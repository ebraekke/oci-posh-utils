# /Users/espenbr/Tools/bin/setenv.ps1 

<#
USE: $env:SSH_CONFIG_FILE=./scripts/Runner.ps1 -BastionId $bastion_ocid -TargetOcidsJson $db_ocids_json -SecretId $sshkey_ocid

 Params are
 - bastion ocid
 - db ocids as json
 - ssh key secret for targets

Now you can:
ssh -F $env:SSH_CONFIG_FILE db-az1-2  


#>
param(
    [Parameter(Mandatory, HelpMessage = 'OCID of Bastion')]
    [String]$BastionId, 
    [Parameter(Mandatory, HelpMessage = 'OCIDs of target hosts as json')]   
    [String]$TargetOcidsJson,
    [Parameter(Mandatory, HelpMessage = 'OCID of secret hold SSH key')]
    [String]$SecretId
)
try {
    ## START: generic section
    $UserErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop" 

    Import-Module "${PSScriptRoot}/../oci-posh-utils.psd1"
    ## END: generic section

    ## Ensure params are ok
    Test-OpuOcidString -OcidString $BastionId -IsOfType "bastion"
    Test-OpuOcidString -OcidString $SecretId -IsOfType "vaultsecret"

    ## Try to convert JSON to list
    try {
        $db_ocid_list = $TargetOcidsJson | ConvertFrom-Json
    }
    catch {
        throw "ConvertFrom-Json: _"
    }

    ## VAlidate each eøemeny of ocid list
    foreach ($db_ocid in $db_ocid_list) {
        Test-OpuOcidString -OcidString $db_ocid -IsOfType "instance"
    }

    ## Grab key
    $key_file = New-OpuSshKeyFromSecret -SecretId $SecretId

    ## Create session
    $bastion_sessions_managed = $db_ocid_list | New-OpuManagedSshSessionFull -BastionId $BastionId -TargetKeyFile $key_file

    ## Create config file
    $ssh_config_file = $bastion_sessions_managed | New-OpuSshConfigFileFromBastionManagedSession -IsProd $false -HostBaseName "db-az1-" -TargetKeyFile $key_file

    $ssh_config_file
}
catch {
    ## What else can we do? 
    Write-Error "Runner.ps1: $_"
    return $false
}
finally {
    Remove-Module oci-posh-utils

    ## START: generic section
    ## To Maximize possible clean ups, continue on error 
    $ErrorActionPreference = "Continue"
#   $ErrorActionPreference = 'SilentlyContinue' 

    ## Request cleanup if session object list has been created
    $ErrorActionPreference = $userErrorActionPreference
    ## END: generic section

}