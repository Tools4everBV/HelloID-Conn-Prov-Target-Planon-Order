#####################################################
# HelloID-Conn-Prov-Target-Planon-Order-Permissions
#
# Version: 1.0.0
#####################################################
# Initialize default values
$config = $configuration | ConvertFrom-Json

# Set debug logging
switch ($($config.IsDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}

try {
    if(-not(Test-Path -Path $($config.OrderCodesJSONFile))){
        throw "Could not find file: [$($config.OrderCodesJSONFile)]"
    } else {
        $permissions = Get-Content $($config.OrderCodesJSONFile) | ConvertFrom-Json
        $permissions.ForEach({
            $_ | Add-Member -NotePropertyMembers @{
                DisplayName = $_.DisplayName
                Identification = @{
                    id = $_.id
                    DisplayName = $_.DisplayName
                }
            }
        })
    }

    Write-Output  $permissions | ConvertTo-Json -Depth 10
} catch {
    $ex = $PSItem
    Write-Verbose "Could not retrieve Planon permissions. Error: $($ex.Exception.Message)"
    Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
}
