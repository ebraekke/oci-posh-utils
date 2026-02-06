<#
.SYNOPSIS
Removes all traces of previously created "full session", that is Bastion session and SSH process.

.DESCRIPTION
The SSH process and the bastion session are destroyed. 
Process will will continue if a failure happens.
Output related to the bastion session deletion will be displayed. 

.PARAMETER BastionSessionDescription

$bastionSessionDescription = [PSCustomObject]@{
    PSTypeName     = 'OpuDynPortForwardingSession.Object'
    TypeNameStr    = "OpuDynPortForwardingSession.Object"
    LifecycleState = "Active"
    BastionSession = $bastionSession
    KeyFileContent = <Content of ssh key file>
    SessionExpires = <SessionExpireTimeInLocalTime>
}
 

.EXAMPLE 

.EXAMPLE 

#>

function Remove-OpuDynPortForwardingSession {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'Bastion Dynamic Port Forwarding Session Description Object')]
        [PSTypeName('OpuDynPortForwardingSession.Object')]$BastionSessionDescription
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue" 
        ## END: generic section

        Write-Verbose "Remove-OpuDynPortForwardingSession: begin"
    }

    process {

        Import-Module OCI.PSModules.Bastion

        ## Already deleted?
        if ("Deleted" -eq $BastionSessionDescription.LifecycleState) {
            Write-Host "Already deleted, no action needed"
            return
        }

        ## Session has exipired?
        if ((Get-Date) -gt $BastionSessionDescription.SessionExpires) {
            Write-Host "Expired, marking as `"Deleted`""
            $BastionSessionDescription.LifecycleState = "Deleted"
            return
        }

        ## Kill Bastion session, with Force, ignore output and error (it is the work request id)
        try {
            Remove-OCIBastionSession -SessionId $BastionSessionDescription.BastionSession.Id -Force -ErrorAction Ignore | Out-Null            
        }
        catch {
            Write-Error "Remove-OpuDynPortForwardingSession: $_"
        }

        ## Mark as deleted
        $BastionSessionDescription.LifecycleState = "Deleted"
    }
   
    end {
        Write-Verbose "Remove-OpuDynPortForwardingSession: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
    
}
