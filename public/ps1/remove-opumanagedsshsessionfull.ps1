<#
.SYNOPSIS
Removes all traces of previously created managed SSH session, that is Bastion session and files process.

.DESCRIPTION
The session is destroyed. 
Process will will continue if a failure happens.
Output related to the bastion session deletion will be displayed. 

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
 
.EXAMPLE 
## Ex 1

.EXAMPLE 
## Ex 2
#>

function Remove-OpuManagedSshsessionFull {
    param (
        [Parameter(Mandatory, ValueFromPipeline=$true, HelpMessage='Full Bastion Port Forwarding Session Description Object')]
        [PSTypeName('OpuManagedBastionSession.Object')]$BastionSessionDescription
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue" 
        ## END: generic section

        Write-Verbose "Remove-OpuPortForwardingSessionFull: begin"
    }

    process {

        Import-Module OCI.PSModules.Bastion
        
        ## Kill Bastion session, with Force, ignore output and error (it is the work request id)
        try {
            Remove-OCIBastionSession -SessionId $BastionSessionDescription.BastionSession.Id -Force -ErrorAction Ignore | Out-Null            
        }
        catch {
            Write-Error "Remove-OpuManagesSshSessionFull: $_"
        }
    }
   
    end {
        Write-Verbose "Remove-OpuManagesSshSessionFull: end"

        ## Delete temp SSH key files
        $ErrorActionPreference = 'SilentlyContinue' 
        Remove-Item $BastionSessionDescription.Keyfile -ErrorAction SilentlyContinue
        Remove-Item "${BastionSessionDescription.Keyfile}.pub" -ErrorAction SilentlyContinue

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
    
}
