<#
.SYNOPSIS
Invoke  an SSH  sesssion with a target host accessible through the OCI Bastion service using a secret from the OCI vault.

.DESCRIPTION
Using the Bastion service and tunneling a SSH session will be invoked on the target host using a secret from the OCI vault as the SSH key. 

The session management wrt the Bastion is handled by cmdlet New-OpuPortForwrdingSessionFull. 
This allows you to "connect" through the Bastion service via a local port and to your destination: $TargetHost:$TargetPort   

A path from the Bastion to the target is required.
The Bastion session inherits TTL from the Bastion (instance). 

.PARAMETER BastionId
OCID of Bastion with wich to create a session. 
 
.PARAMETER TargetHost
IP address of target host. 

.PARAMETER SecretId
OCID of secret holding the SSH key for this host. 

.PARAMETER TargetPort
Port number at TargetHost to create a session to. 
Defaults to 22.  

.PARAMETER OsUser
Os user to connect with at target. 
Defaults to opc. 

.EXAMPLE 
## Create a SSH session to the default port with the default user
❯.\Invoke_Ssh_Session.ps1 -BastionId $bastion_ocid -TargetHost 10.0.1.102 -SecretId $ssh_key_ocid
Getting the SSH key from the secrets vault
Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.102:22
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting until SSH tunnel is ready (10 seconds)
Validating downloaded key...

...

Last login: Sun Mar  5 16:29:54 2023 from 10.0.0.49

.EXAMPLE 
## Failed creation of SSH session wit han incorrect username 
./scripts/Invoke_Ssh_Session.ps1 -BastionId $bastion_ocid -TargetHost 10.0.1.65 -SecretId $sshkey_ocid -OsUser xyz
Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.65:22
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting for creation of SSH tunnel to complete
xyz@localhost: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).

.EXAMPLE 
## Failed creation of SSH session because of invalid SSH key
./scripts/Invoke_Ssh_Session.ps1 -BastionId $bastion_ocid -TargetHost 10.0.1.65 -SecretId $bad_secret
Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.65:22
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting for creation of SSH tunnel to complete
Load key "/var/folders/9w/tt305cd54dz5ktqzh82t4tvw0000gp/T//BastionSession-2025_11_28_15_42_04-9036-27483": invalid format
Write-Error: Invoke_Ssh_Session.ps1: New-OpuSshKeyFromSecret: New-OpuSshKeyFromSecret: SecretId points to a invalid private SSH key
>
#>

param(
    [Parameter(Mandatory, HelpMessage='OCID of Bastion')]
    [String]$BastionId, 
    [Parameter(Mandatory,HelpMessage='IP address of target host')]   
    [String]$TargetHost,
    [Parameter(Mandatory, HelpMessage='OCID of secret hold SSH key')]
    [String]$SecretId,
    [Parameter(HelpMessage='Port at Target host')]
    [Int32]$TargetPort=22,
    [Parameter(HelpMessage='User to connect at target (opc)')]
    [String]$OsUser="opc"
)

Write-Verbose "Invoke_Ssh_Session.ps1: PSScriptRoot = ${PSScriptRoot}"

try {
    ## START: generic section
    $UserErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop" 

    Import-Module "${PSScriptRoot}/../oci-posh-utils.psd1"
    ## END: generic section

    ## Ensure params are ok
    Test-OpuOcidString -OcidString $BastionId -IsOfType "bastion"
    Test-OpuIpAddr -IpAddr $TargetHost
    Test-OpuOcidString -OcidString $SecretId -IsOfType "vaultsecret"

    ## Validate that ssh is omdeed available
    Test-OpuSshAvailable

    ## Create session and process, get information in custom object -- see below
    $bastionSessionDescription = New-OpuPortForwardingSessionFull -BastionId $BastionId -TargetHost $TargetHost -TargetPort $TargetPort
    $localPort = $bastionSessionDescription.LocalPort

    $sshKey= New-OpuSshKeyFromSecret -SecretId $SecretId -KeyBaseName $bastionSessionDescription.BastionSession.DisplayName    
    
    ## NOTE 1: 'localhost' and not '127.0.0.1'
    ## Behaviour with both ssh and putty is unreliable when not using 'localhost'.
    ## NOTE 2: -o 'NoHostAuthenticationForLocalhost yes' 
    ## Ensures no verification of locally forwarded port and localhost combos. 
    ssh -4 -o 'NoHostAuthenticationForLocalhost yes' -p $localPort localhost -l $OsUser -i $sshKey
}
catch {
    ## What else can we do? 
    Write-Error "Invoke_Ssh_Session.ps1: $_"
    return $false
}
finally {
    ## START: generic section
    Remove-Module oci-posh-utils

    ## To Maximize possible clean ups, continue on error 
    $ErrorActionPreference = "Continue"
    
    ## Request cleanup if session object has been created
    if ($null -ne $bastionSessionDescription) {
        Remove-OpuPortForwardingSessionFull -BastionSessionDescription $bastionSessionDescription
    }

    ## Delete temp SSH key file
    $ErrorActionPreference = 'SilentlyContinue' 
    Remove-Item $SshKey -ErrorAction SilentlyContinue
    $ErrorActionPreference = "Continue"
    ## Done, restore settings
    $ErrorActionPreference = $userErrorActionPreference
    ## END: generic section
}
