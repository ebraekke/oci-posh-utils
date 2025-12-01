<#
Build OCI config file from env vars: 

'OCI_USER_OCID',
'OCI_TENANCY_OCID',
'OCI_FINGERPRINT',
'OCI_KEY_CONTENT',
'OCI_REGION'

Validate that the _OCID ones are acuatlly ocids 

Create a (temp) file and format as proper OCI config 

Return name of file
#>
function New-OpuOciConfigFileFromEnv {
    param (
    )

    try {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        ## Populate env vars
        $ociEnvVarList = @(
            'OCI_USER_OCID',
            'OCI_TENANCY_OCID',
            'OCI_FINGERPRINT',
            'OCI_KEY_CONTENT',
            'OCI_REGION'
        )

        # Ensure all are set
        $loopCnt = 0
        foreach ($ociEnvVar in $ociEnvVarList) {
            Write-Output "Validating:"
            try {
                $envVarValue = (Get-ChildItem Env:$ociEnvVar).Value
                Write-Output "${ociEnvVar} = ${envVarValue}"
            }
            catch {
                throw "${ociEnvVar} not set"
            }            
            $loopCnt++
        }

    }
    catch {
        throw "Test-OpuIpAddr: $_"
    }
    finally {
 
        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
}
