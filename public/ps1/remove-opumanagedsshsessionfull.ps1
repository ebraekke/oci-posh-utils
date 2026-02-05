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
    KeyFile        = <key file generated for the session>
    JumpUser       = <jump user for the session>
    JumpHost       = <jump host for the session>
    TargetUser     = <target user for the session>
    TargetHost     = <target host for the session>
    TargetPort     = <target port for the session<
    SshConfig      = <entry for ssh config file>
    SessionExpires = <SessionExpireTimeInLocalTime>
}
 
.EXAMPLE 
## Ex 1

.EXAMPLE 
## Ex 2
#>

function Remove-OpuManagedSshsessionFull {
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'Full Bastion Port Forwarding Session Description Object')]
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
        finally {
            ## Delete temp SSH key files
            ## set local variable, don't know why -- but it works!
            $removeMe = $BastionSessionDescription.Keyfile
            Write-Verbose "Removing: ${removeMe}"
            Remove-Item $removeMe -ErrorAction SilentlyContinue

            $removeMe = $removeMe + ".pub"
            Write-Verbose "Removing: ${removeMe}"
            Remove-Item $removeMe -ErrorAction SilentlyContinue
        }
    }
   
    end {
        Write-Verbose "Remove-OpuManagesSshSessionFull: end"
        
        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
    
}
