
<#
.SYNOPSIS
x

.DESCRIPTION
y

.PARAMETER BastionSessionDescription

$bastionSessionDescription = [PSCustomObject]@{
    PSTypeName = 'OpuPortBastionSession.Object'
    BastionSession = $bastionSession
    SShProcess = $sshProcess
    LocalPort = $useThisPort
    TargetHost = $TargetHost
    TargetPort = $TargetPort
    SessionExpires = <SessionExpireTimeInLocalTime>
}
 
#>

function New-OpuSshConfigFileFromBastionSession {
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'Full Bastion Port Forwarding Session Description Object')]
        [PSTypeName('OpuPortBastionSession.Object')]$BastionSessionDescription, 
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

        Write-Verbose "New-OpuSshConfigFileFromBastionSession: begin"
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
        Out-Host -InputObject "  ServerAliveInterval 120"
        Out-Host -InputObject "  ServerAliveCountMax 90"

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
        Write-Verbose "New-OpuSshConfigFileFromBastionSession: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
    
}
