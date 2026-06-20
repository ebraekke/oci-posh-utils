
# Abondoned


## Cmdlet `New-OpuSshConfigFileFromBastionPortForwardingSession`

```PowerShell

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

function New-OpuSshConfigFileFromBastionPortForwardingSession {
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
        Write-Verbose "New-OpuSshConfigFileFromBastionSession: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
    
}
```



## Cmdlet `Test-OpuPortForwardingSessionFull `

```powershell
<#
.SYNOPSIS
Test if background SSH process for a BastionSessionDecription is still running. 

.DESCRIPTION
Tests if the ID of the SSH process in the BastionSessionDescription input object is still running.    
If more than one session object is given, the verfification process will throw an error on the first non running process.

.PARAMETER BastionSessionDescription

$BastionSessionDescription = [PSCustomObject]@{
    PSTypeName = 'OpuPortBastionSession.Object'
    BastionSession = $bastionSession
    SShProcess = $sshProcess
    LocalPort = $localPort
    Target = "${TargetHost}:${TargetPort}"
    SessionExpires = <SessionExpireTimeInLocalTime>
}
 
.EXAMPLE 
## Successful validation of the SSH process of one Bastion Session Description object. 

❯ Test-OpuPortForwardingSessionFull -BastionSessionDescription $bastion_session_list[0]

.EXAMPLE
## Failed validation of the SSH process of one Bastion Session Description object. 

❯ Test-OpuPortForwardingSessionFull -BastionSessionDescription $bastion_session_list[1]

Exception: C:\Users\espenbr\GitHub\oci-posh-utils\public\ps1\test-opuportforwardingsessionfull.ps1:60
Line |
  60 |              Throw "Test-OpuPortForwardingSessionFull: $_"
     |              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Test-OpuPortForwardingSessionFull: Cannot find a process with the process identifier 28208.

.EXAMPLE 
## Pipeline a list of Bastion Sessions Description object where (at least) one has a SSH process that has stopped.

❯ $bastion_session_list | Test-OpuPortForwardingSessionFull

Exception: C:\Users\espenbr\GitHub\oci-posh-utils\public\ps1\test-opuportforwardingsessionfull.ps1:52
Line |
  52 |              Throw "Test-OpuPortForwardingSessionFull: $_"
     |              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Test-OpuPortForwardingSessionFull: Cannot find a process with the process identifier 28208

#>

function Test-OpuPortForwardingSessionFull {
    param (
        [Parameter(Mandatory, ValueFromPipeline=$true, HelpMessage='Full Bastion Port Forwarding Session Description Object')]
        [PSTypeName('OpuPortBastionSession.Object')]$BastionSessionDescription
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        Write-Verbose "Test-OpuPortForwardingSessionFull: begin"
    }

    process {
        
        ## Check status of process, ignore output
        try {
            Get-Process -Id $BastionSessionDescription.SShProcess.Id -ErrorAction Stop | Out-Null 
        }
        catch {
            Throw "Test-OpuPortForwardingSessionFull: $_"
        }
    }
   
    end {
        Write-Verbose "Test-OpuPortForwardingSessionFull: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
}
```

