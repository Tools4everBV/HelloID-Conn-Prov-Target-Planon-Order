#####################################################
# HelloID-Conn-Prov-Target-Planon-Order-Create
#
# Version: 1.0.0
#####################################################
# Initialize default values
$config = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$success = $false
$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::new()

# Account mapping
$account = [PSCustomObject]@{
    ExternalId = $p.ExternalId
}

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Set debug logging
switch ($($config.IsDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}

#region functions
function Resolve-PlanonError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = ''
            FriendlyMessage  = ''
        }
        $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
        $xmlResponse = [xml]$streamReaderResponse
        $httpErrorObj.ErrorDetails = $xmlResponse.Envelope.Body.Fault.Reason.Text.'#text'
        $httpErrorObj.FriendlyMessage = $xmlResponse.Envelope.Body.Fault.Reason.Text.'#text'

        Write-Output $httpErrorObj
    }
}
#endregion

# Begin
try {
    if ($dryRun -eq $true) {
        Write-Warning "[DryRun] Correlate Planon account for: [$($p.DisplayName)], will be executed during enforcement"
    }

    if (-not $dryRun -eq $true) {
        Write-Verbose "Correlating Planon account for: [$($p.DisplayName)]"
        Write-Verbose 'Adding authorization header'
        $pair = "$($config.UserName):$($config.Password)"
        $b64Encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
        $headers = [system.collections.generic.dictionary[string, string]]::new()
        $headers.add('Authorization', "Basic $b64Encoded")

        $body = @"
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://www.tempsdw.org/SDWWebServices/v1/ws">
            <soapenv:Body>
                <ws:GetPerson>
                    <code>($account.ExternalId)</code>
                </ws:GetPerson>
            </soapenv:Body>
        </soapenv:Envelope>
"@

        $splatParams = @{
            Uri         = "$($config.BaseUrl)/SDWWebServices.SDWWebServicesSOAP"
            Method      = 'POST'
            Headers     = $headers
            Body        = $body
            ContentType = 'application/text+xml; charset=utf-8'
        }
        <#
            TODO: - Retrieve account from Planon.
                  - Verify errorHandling when the account does not exist.
                  - Correlate on the <PersonnelNumber>.
        #>
        $responseUser = Invoke-RestMethod @splatParams
        $accountReference = $responseUser.PersonnelNumber

        $success = $true
        $auditLogs.Add([PSCustomObject]@{
                Message = "Correlate account was successful. AccountReference is: [$accountReference]"
                IsError = $false
            })
    }
} catch {
    $success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-PlanonError -ErrorObject $ex
        $auditMessage = "Could not $action Planon account. Error: $($errorObj.FriendlyMessage)"
        Write-Verbose "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        $auditMessage = "Could not $action Planon account. Error: $($ex.Exception.Message)"
        Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $auditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
# End
} finally {
    $result = [PSCustomObject]@{
        Success          = $success
        AccountReference = $accountReference
        Auditlogs        = $auditLogs
        Account          = $account
    }
    Write-Output $result | ConvertTo-Json -Depth 10
}
