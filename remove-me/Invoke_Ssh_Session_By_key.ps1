<#
#>

param(
    [Parameter(Mandatory, HelpMessage = 'OCID of Bastion')]
    [String]$BastionId, 
    [Parameter(Mandatory, HelpMessage = 'IP address of target host')]   
    [String]$TargetHost,
    [Parameter(Mandatory, HelpMessage = 'Content of SSH key')]
    [String]$KeyContent,
    [Parameter(HelpMessage = 'Port at Target host')]
    [Int32]$TargetPort = 22,
    [Parameter(HelpMessage = 'User to connect at target (opc)')]
    [String]$OsUser = "opc"
)

Write-Verbose "Invoke_Ssh_Session_By_Key.ps1: PSScriptRoot = ${PSScriptRoot}"

try {
    ## START: generic section
    $UserErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop" 

    Import-Module "${PSScriptRoot}/../oci-posh-utils.psd1"
    ## END: generic section

    ## Ensure params are ok
    Test-OpuOcidString -OcidString $BastionId -IsOfType "bastion"
    Test-OpuIpAddr -IpAddr $TargetHost

    ## Validate that ssh is omdeed available
    Test-OpuSshAvailable

    ## Create session and process, get information in custom object -- see below
    $bastionSessionDescription = New-OpuPortForwardingSessionFull -BastionId $BastionId -TargetHost $TargetHost -TargetPort $TargetPort
    $localPort = $bastionSessionDescription.LocalPort

    $sshKey = New-TemporaryFile
    $KeyContent | Out-File -FilePath $sshKey.FullName
    
    ## NOTE 1: 'localhost' and not '127.0.0.1'
    ## Behaviour with both ssh and putty is unreliable when not using 'localhost'.
    ## NOTE 2: -o 'NoHostAuthenticationForLocalhost yes' 
    ## Ensures no verification of locally forwarded port and localhost combos. 
    ssh -4 -o 'NoHostAuthenticationForLocalhost yes' -p $localPort localhost -l $OsUser -i $sshKey
}
catch {
    ## What else can we do? 
    throw "Invoke_Ssh_Session_By_Key.ps1: $_"
}
finally {
    ## START: generic section

    ## To Maximize possible clean ups, continue on error 
    $ErrorActionPreference = "Continue"
    
    ## Request cleanup if session object has been created
    if ($null -ne $bastionSessionDescription) {
        Remove-OpuPortForwardingSessionFull -BastionSessionDescription $bastionSessionDescription
    }

    ## Now remove module from memory
    ## Remove-Module oci-posh-utils

    ## Delete temp SSH key file
    $ErrorActionPreference = 'SilentlyContinue' 
    Remove-Item $sshKey -ErrorAction SilentlyContinue
    $ErrorActionPreference = "Continue"
    ## Done, restore settings
    $ErrorActionPreference = $userErrorActionPreference
    ## END: generic section
}
