<#
.SYNOPSIS
Test if background SSH process for a BastionSessionDecription is still running. 

.DESCRIPTION
Tests if the ID of the SSH process in the BastionSessionDescription input object is still running.    
If more than one session object is given, the verfification process will throw an error on the first non running process.

.PARAMETER BastionSessionDescription

$BastionSessionDescription = [PSCustomObject]@{
    PSTypeName = 'OpuBastionSession.Object'
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
        [PSTypeName('OpuBastionSession.Object')]$BastionSessionDescription
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
