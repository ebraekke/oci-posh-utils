<#
.SYNOPSIS
Removes all traces of previously created "full session", that is Bastion session and SSH process.

.DESCRIPTION
The SSH process and the bastion session are destroyed. 
Process will will continue if a failure happens.
Output related to the bastion session deletion will be displayed. 

.PARAMETER BastionSessionDescription

$bastionSessionDescription = [PSCustomObject]@{
    PSTypeName = 'OpuDynPortBastionSession.Object'
    BastionSession = $bastionSession
    SShProcess = $sshProcess
    LocalPort = $useThisPort
    SessionExpires = <SessionExpireTimeInLocalTime>
}
 

.EXAMPLE 

.EXAMPLE 

#>

function Remove-OpuDynPortForwardingSessionFull {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline=$true, HelpMessage='Full Bastion Dynamic Port Forwarding Session Description Object')]
        [PSTypeName('OpuDynPortBastionSession.Object')]$BastionSessionDescription
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue" 
        ## END: generic section

        Write-Verbose "Remove-OpuDynPortForwardingSessionFull: begin"
    }

    process {

        Import-Module OCI.PSModules.Bastion

        ## Kill SSH process
        Stop-Process -InputObject $BastionSessionDescription.SshProcess -ErrorAction SilentlyContinue
        
        ## Kill Bastion session, with Force, ignore output and error (it is the work request id)
        try {
            Remove-OCIBastionSession -SessionId $BastionSessionDescription.BastionSession.Id -Force -ErrorAction Ignore | Out-Null            
        }
        catch {
            Write-Error "Remove-OpuDynPortForwardingSessionFull: $_"
        }
    }
   
    end {
        Write-Verbose "Remove-OpuDynPortForwardingSessionFull: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
    
}
