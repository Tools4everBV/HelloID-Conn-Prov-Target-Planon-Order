##########################################################
# HelloID-Conn-Prov-Target-Planon-Order-Entitlement-Grant
#
# Version: 1.0.0
##########################################################
# Initialize default values
$config = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$aRef = $AccountReference | ConvertFrom-Json
$pRef = $permissionReference | ConvertFrom-Json
$success = $false
$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::new()

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
    Write-Verbose 'Adding authorization header'
    $pair = "$($config.UserName):$($config.Password)"
    $b64Encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $headers = [system.collections.generic.dictionary[string, string]]::new()
    $headers.add('Authorization', "Basic $b64Encoded")

    # Process
    if (-not($dryRun -eq $true)) {
        Write-Verbose "Granting Planon entitlement: [$($pRef.Reference)]"

        $body = @"
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:umr="http://www.example.org/UmraOrders/">
            <soapenv:Body>
                <umr:MaakOrder>
                    <PersonnelNumber>$($aRef)</PersonnelNumber>
                    <StandardOrderCode>$($pRef.Reference)</StandardOrderCode>
                    <!--Optional:-->
                    <Comment>Processed from HelloID</Comment>
                </umr:MaakOrder>
            </soapenv:Body>
        </soapenv:Envelope>
"@

        $splatParams = @{
            Uri         = "$($config.BaseUrl)/UmraOrders"
            Method      = 'POST'
            Headers     = $headers
            Body        = $body
            ContentType = 'application/text+xml; charset=utf-8'
        }
        $null = Invoke-RestMethod @splatParams

        $success = $true
        $auditLogs.Add([PSCustomObject]@{
                Message = "Grant Planon entitlement: [$($pRef.Reference)] was successful"
                IsError = $false
            })
    }
} catch {
    $success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-PlanonError -ErrorObject $ex
        $auditMessage = "Could not grant Planon account. Error: $($errorObj.FriendlyMessage)"
        Write-Verbose "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        $auditMessage = "Could not grant Planon account. Error: $($ex.Exception.Message)"
        Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $auditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
# End
} finally {
    $result = [PSCustomObject]@{
        Success   = $success
        Auditlogs = $auditLogs
    }
    Write-Output $result | ConvertTo-Json -Depth 10
}
