/Users/espenbr/Tools/bin/setenv.ps1 

<#
 Params are
 - db ocids as json 
 - bastion ocid
 - ssh key secret for targets
#>

try {
    ## START: generic section
    $UserErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop" 

    Import-Module "${PSScriptRoot}/../oci-posh-utils.psd1"
    ## END: generic section

    <#
    - convert json string to list
    - create bastion sessions 
    - create ssh config file
    - return name/location of ssh config file
    #>
 
} catch {
    ## What else can we do? 
    Write-Error "runner.ps1: $_"
    return $false
} finally {
    Remove-Module oci-posh-utils
}