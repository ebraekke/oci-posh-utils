<#
.SYNOPSIS
Removes all traces of previously created "full session", that is Bastion session and SSH process.

.DESCRIPTION
The SSH process and the bastion session are destroyed. 
Process will will continue if a failure happens.
Output related to the bastion session deletion will be displayed. 

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
## Removing previously created full session
Remove-OpuPortForwardingSessionFull -BastionSessionDescription $full_session

.EXAMPLE 
## Attempting to remove a full session that has already been removed. 
Remove-OpuPortForwardingSessionFull -BastionSessionDescription $full_session
Line |
  54 |      Remove-OpuPortForwardingSessionFull -BastionSessionDescription $B …
     |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Remove-OpuPortForwardingSessionFull: Error returned by Bastion Service. Http Status Code: 409. ServiceCode: Conflict.
     | OpcRequestId: /80B4D7579823F8E5A114897FB5FA2700/E9666BAA4D1FE96AD3DBD003CC8A9D6D. Message: resource is not allowed to delete
     | with current state Operation Name: DeleteSession TimeStamp: 2023-02-14T13:10:02.584Z Client Version: Oracle-DotNetSDK/51.3.0
     | (Win32NT/10.0.19044.0; .NET 7.0.2)  Oracle-PowerShell/47.3.0  Request Endpoint: DELETE
     | https://bastion.eu-frankfurt-1.oci.oraclecloud.com/20210331/sessions/ocid1.bastionsession.oc1.eu-frankfurt-1.amaaaaaa3gkdkiaacko5aymp2ztq5rm2lstumpzimqn5t7kiszv2e76w5ghq For details on this operation's requirements, see https://docs.oracle.com/iaas/api/#/en/bastion/20210331/Session/DeleteSession. Get more information on a failing request by using the -Verbose or -Debug flags. See https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/powershellconcepts.htm#powershellconcepts_topic_logging For more information about resolving this error, see https://docs.oracle.com/en-us/iaas/Content/API/References/apierrors.htm#apierrors_409__409_conflict If you are unable to resolve this Bastion issue, please contact Oracle support and provide them this full error message.

#>

function Remove-OpuPortForwardingSessionFull {
    param (
        [Parameter(Mandatory, ValueFromPipeline=$true, HelpMessage='Full Bastion Port Forwarding Session Description Object')]
        [PSTypeName('OpuBastionSession.Object')]$BastionSessionDescription
    )

    begin {
        Write-Verbose "Remove-OpuPortForwardingSessionFull: begin"

        ## TODO: Review ErrorAction across board
        ## To Maximize possible clean ups, continue on error
        $userErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
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
            Write-Error "Remove-OpuPortForwardingSessionFull: $_"
        }
    }
   
    end {
        Write-Verbose "Remove-OpuPortForwardingSessionFull: end"

        ## Done, restore settings
        $ErrorActionPreference = $userErrorActionPreference
    }    
    
}
