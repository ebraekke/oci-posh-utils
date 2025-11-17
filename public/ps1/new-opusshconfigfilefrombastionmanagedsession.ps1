
<#
.SYNOPSIS
x

.DESCRIPTION
Output:

Host <HOST-BASE-NAME>1
  HostName <TARGET-IP-INSIDE-VCN>
  User <USERNAME-GIVEN-WHEN-SESSION-CREATED>
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  IdentityFile <FULL-NAME-OF-INPUT-KEY-HERE>
  UserKnownHostsFile /dev/null
  ProxyCommand ssh -i /tmp/bastionkey-2025_11_07_11_25_41-9087 -W %h:%p -p 22 ocid1.bastionsession.oc1.eu-frankfurt-1.<OCI-UUID>@host.bastion.<OCI-REGION>.oci.oraclecloud.com

.PARAMETER BastionSessionDescription

$BastionSessionDescription = [PSCustomObject]@{
    PSTypeName     = 'OpuManagedBastionSession.Object'
    BastionSession = $bastionSession
    SShArgs        = <fully formated ssh command>
    KeyFile        = <key file generated for the session>
    JumpUser       = <jump user for the session>
    JumpHost       = <jump host for the session>
    TargetUser     = <target user for the session>
    TargetHost     = <target host for the session>
    TargetPort     = <target port for the session<
    SessionExpires = <SessionExpireTimeInLocalTime>
}


 
#>

function New-OpuSshConfigFileFromBastionManagedSession {
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'Full Bastion Port Forwarding Session Description Object')]
        [PSTypeName('OpuManagedBastionSession.Object')]$BastionSessionDescription, 
        [Parameter(Mandatory, HelpMessage = 'Base name to use when defining Host in config')]
        [String]$HostBaseName,
        [Parameter(Mandatory, HelpMessage = 'Name of keyfile to add to target for the $OsUser')]
        [String]$TargetKeyFile,
        [Parameter(HelpMessage = 'Is this a production config ($false)')]
        [bool]$IsProd = $false,
        [Parameter(HelpMessage = 'User to connect at target (ubuntu)')]
        [String]$TargetUser = "opc"
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue" 
        ## END: generic section

        ## "Iterator" for assigning host names
        $globalCount = 0

        Write-Verbose "New-OpuSshConfigFileFromBastionManagedSession: begin"
    }

    process {

        $globalCount++

        $_targetHost = $BastionSessionDescription.Targethost
        $_targetPort = $BastionSessionDescription.LocalPort
        $_targetUser = $TargetUser

        Out-Host -InputObject "#"
        Out-Host -InputObject "# ${HostBaseName} number ${globalCount} - target ${_targetHost}"
        Out-Host -InputObject "Host ${HostBaseName}${globalCount}"
        Out-Host -InputObject "  Hostname localhost"
        Out-Host -InputObject "  User ${_targetUser}"
        Out-Host -InputObject "  Port ${_targetPort}"
        Out-Host -InputObject "  IdentityFile ${TargetKeyFile}"
        Out-Host -InputObject "  ServerAliveInterval 30"
        Out-Host -InputObject "  ServerAliveCountMax 4"

        if ($false -eq $IsProd) {
            Out-Host -InputObject "  StrictHostKeyChecking no"
            if ($false -eq $IsWindows) {
                Out-Host -InputObject "  UserKnownHostsFile=/dev/null"
            }
            else {
                Out-Host -InputObject "  UserKnowHostFile=\\.\NUL"
            }
        }
    }
   
    end {
        Write-Verbose "New-OpuSshConfigFileFromBastionManagedSession: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
    
}
