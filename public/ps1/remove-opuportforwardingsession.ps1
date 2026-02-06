<#

$bastionSessionDescription = [PSCustomObject]@{
    PSTypeName     = 'OpuPortForwardingSession.Object'
    TypeNameStr    = "OpuPortForwardingSession.Object"
    LifecycleState = "Active"
    BastionSession = $bastionSession
    TargetHost = $TargetHost
    TargetPort = $TargetPort
    KeyFileContent = <Content of ssh key file>
    SessionExpires = <SessionExpireTimeInLocalTime>
}
 

#>

function Remove-OpuPortForwardingSession {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'Bastion Port Forwarding Session Description Object')]
        [PSTypeName('OpuPortForwardingSession.Object')]$BastionSessionDescription
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue" 
        ## END: generic section

        Write-Verbose "Remove-OpuPortForwardingSession: begin"
    }

    process {

        Import-Module OCI.PSModules.Bastion

        ## Already deleted?
        if ("Deleted" -eq $BastionSessionDescription.LifecycleState) {
            Write-Host "Already deleted, no action needed"
            return
        }

        ## Sessioin has exipired?
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
            Write-Error "Remove-OpuPortForwardingSession: $_"
        }

        ## Mark as deleted
        $BastionSessionDescription.LifecycleState = "Deleted"
    }
   
    end {
        Write-Verbose "Remove-OpuPortForwardingSession: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
    
}
