<#
Build OCI config file from env vars: 

Renamed from default used by GitHub OCI inetrgration for cli

            'OCI_USER_OCID',
            'OCI_TENANCY_OCID',
            'OCI_KEY_CONTENT',
            'OCI_REGION'



Validate that the _OCID ones are acuatlly ocids 

Create a (temp) file and format as proper OCI config 

Return name of file

$temp_config = New-OpuOciConfigFileFromEnv

oci iam region list --config-file $temp_config_file
#>
function New-OpuOciConfigFileFromEnv {
    [CmdletBinding()]
    param()
    try {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        ## Populate env var names
        $ociEnvVarList = @(
            'OCI_USER_OCID',
            'OCI_TENANCY_OCID',
            'OCI_KEY_CONTENT',
            'OCI_REGION'
        )

        ## Ensure all are set
        foreach ($ociEnvVar in $ociEnvVarList) {
            Write-Verbose "Validating: ${ociEnvVar}"
            try {
                $envVarValue = (Get-ChildItem Env:$ociEnvVar).Value
            }
            catch {
                throw "${ociEnvVar} not set"
            }            
        }

        Write-Verbose "Creating temp config file"
        ## check validity of content
        Test-OpuOcidString -OcidString $env:OCI_USER_OCID -IsOfType "user"
        Test-OpuOcidString -OcidString $env:OCI_TENANCY_OCID -IsOfType "tenancy"

        ## Populate temp file for pem key first 
        $pemKeyFile = New-TemporaryFile
        Out-File -Append -FilePath $pemKeyFile -InputObject $env:OCI_KEY_CONTENT

        # Get fingeprint, should work on all OSs
        try {
            Write-Verbose "Getting fingerprint"
            $fingerPrint = (type $pemKeyFile | openssl rsa -pubout -outform DER | openssl md5 -c)
        } 
        catch {
            throw "openssl: $_"
        }

        ## Temp config & key
        $tempFile = New-TemporaryFile

        Out-File -Append -FilePath $tempFile -InputObject "[DEFAULT]" 
        Out-File -Append -FilePath $tempFile -InputObject "user = ${env:OCI_USER_OCID}" 
        Out-File -Append -FilePath $tempFile -InputObject "fingerprint = ${fingerPrint}" 
        Out-File -Append -FilePath $tempFile -InputObject "tenancy = ${env:OCI_TENANCY_OCID}" 
        Out-File -Append -FilePath $tempFile -InputObject "region = ${env:OCI_REGION}" 
        Out-File -Append -FilePath $tempFile -InputObject "key_file = ${pemKeyFile}" 

        $tempFile.FullName
    }
    catch {
        throw "New-OpuOciConfigFileFromEnv: $_"
    }
    finally {
 
        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
}
