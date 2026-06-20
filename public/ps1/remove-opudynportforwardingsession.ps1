<#
.SYNOPSIS
Removes bastion session of type dyn.

.DESCRIPTION
The bastion session is destroyed. 
Process will will continue if a failure happens.
Output related to the bastion session deletion will be displayed. 

.PARAMETER BastionSessionDescription

$BastionSessionDescription = [PSCustomObject]@{
    PSTypeName  = 'OpuDynPortForwardingSession.Object'
    TypeNameStr = "OpuDynPortForwardingSession.Object"
    id          = $bastionSession.Id
    data        = [PSCustomObject]@{
        LifecycleState = "Active"
        BastionSession = $bastionSession
        KeyFileContent = $keyFileContent
        SessionExpires = (Get-Date).AddSeconds($bastionSession.SessionTtlInSeconds - 300)
    }
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
        if ("Deleted" -eq $BastionSessionDescription.data.LifecycleState) {
            Write-Host "Already deleted, no action needed"
            return
        }

        ## Session has exipired?
        if ((Get-Date) -gt $BastionSessionDescription.data.SessionExpires) {
            Write-Host "Expired, marking as `"Deleted`""
            $BastionSessionDescription.data.LifecycleState = "Deleted"
            return
        }

        ## Kill Bastion session, with Force, ignore output and error (it is the work request id)
        try {
            Remove-OCIBastionSession -SessionId $BastionSessionDescription.data.BastionSession.Id -Force -ErrorAction Ignore | Out-Null            
        }
        catch {
            Write-Error "Remove-OpuDynPortForwardingSession: $_"
        }

        ## Mark as deleted
        $BastionSessionDescription.data.LifecycleState = "Deleted"
    }
   
    end {
        Write-Verbose "Remove-OpuDynPortForwardingSession: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
    
}
