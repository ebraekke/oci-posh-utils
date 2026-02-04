<#
.SYNOPSIS
Create a mamnaged SSH sesssion with OCI Bastion service.

Return an object to the caller:

$bastionSessionDescription = [PSCustomObject]@{
    PSTypeName     = 'OpuManagedBastionSession.Object'
    BastionSession = $bastionSession
    KeyFile        = <key file generated for the session>
    JumpUser       = <jump user for the session>
    JumpHost       = <jump host for the session>
    TargetUser     = <target user for the session>
    TargetHost     = <target host for the session>
    TargetPort     = <target port for the session<
    SessionExpires = <SessionExpireTimeInLocalTime>
}

The SshCmd attribute contains a formated SSH command string that can be used directly on the command line.
The KeyFile, JumpUser/JumpHost & TargetUser/TargetHost/TargetPort are intended for use with automation tools 
such as Ansible and PyInfra.   
        
.DESCRIPTION
Creates a managed SSH session with the OCI Bastion Service.
Requires that bastion plugin is installed on the agent *and* that it is running (there is a slight delay at create time).
A path from the Bastion to the target is required.
The Bastion session inherits TTL from the Bastion (instance). 

.PARAMETER TargetHostId
OCID of target host. 
ValueFromPipeline = $true

.PARAMETER BastionId
OCID of Bastion with whitch to create a session. 

.PARAMETER TargetPort
Port number at TargetHostId to create a session to. 
Defaults to 22.  

.PARAMETER OsUser
Os user to connect to at target.
Defaults to "opc".

.PARAMETER TargetKeyFile
Name of keyfile that caller wishes to be merged into the output to form the SshCmd attribute of the return object. 

.EXAMPLE 
## Call to create managed session before agent has properly started.
> $bastion_session = $target_host_ocid | New-OpuManagedSshSessionFull -BastionId $bastion_ocid -TargetKeyFile /tmp/db-10610

Exception: /Users/espenbr/GitHub/oci-posh-utils/public/ps1/new-opumanagedsshsessionfull.ps1:140
Line |
 140 |              throw "New-OpuManagedSshSessionFull: $_"
     |              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | New-OpuManagedSshSessionFull: New-OciBastionSession: Error returned by Bastion Service. Http Status Code: 400. ServiceCode:
     | InvalidParameter. OpcRequestId:
     | oci-64C360387C63FA3-202511041701/C8F03257005891A278310A6946524123/57491B58CD2BA8D6C4D5DA607091DBBF. Message: To create a
     | Managed SSH session, the Bastion plugin must be in the RUNNING state on the target instance, but the plugin is not running
     | on ocid1.instance.oc1.eu-frankfurt-1.antheljt3gkdkiacxz76jwglc2nb2taejxpnt5yobndzet6u5csvxqiidokq. Enable the Bastion
     | plugin on the target instance before creating the session. Operation Name: CreateSession TimeStamp:
     | 2025-11-04T18:01:45.056Z Client Version: Oracle-DotNetSDK/122.0.0 (Unix/15.7.1; .NET 9.0.10)  Oracle-PowerShell/118.0.0 
     | Request Endpoint: POST https://bastion.eu-frankfurt-1.oci.oraclecloud.com/20210331/sessions For details on this operation's
     | requirements, see https://docs.oracle.com/iaas/api/#/en/bastion/20210331/Session/CreateSession. Get more information on a
     | failing request by using the -Verbose or -Debug flags. See
     | https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/powershellconcepts.htm#powershellconcepts_topic_logging For more
     | information about resolving this error, see
     | https://docs.oracle.com/en-us/iaas/Content/API/References/apierrors.htm#apierrors_400__400_invalidparameter If you are
     | unable to resolve this Bastion issue, please contact Oracle support and provide them this full error message.

.EXAMPLE 
## Creating a number of managed sessions based on a list of instance ocids

#>
function New-OpuManagedSshSessionFull {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'OCID of target host')]
        [String]$TargetHostId,
        [Parameter(Mandatory, HelpMessage = 'OCID of Bastion')]
        [String]$BastionId, 
        [Int32]$TargetPort = 22,
        [Parameter(HelpMessage = 'User to connect at target (opc)')]
        [String]$OsUser = "opc",
        [Parameter(HelpMessage = 'Is this a production config ($false)')]
        [bool]$IsProd = $false
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        Write-Verbose "New-OpuManagedSshSessionFull: begin"

        ## "Iterator" for comtrolling behavior with mulrpile input objects
        $globalCount = 0
    }

    process {
        try {
            ## check that mandatory sw is installed    
            Test-OpuSshAvailable

            ## Check input parameters
            Test-OpuOcidString -OcidString $TargetHostId -IsOfType "instance"
            Test-OpuOcidString -OcidString $BastionId -IsOfType "bastion"

            ## Import modules
            Import-Module OCI.PSModules.Bastion

            ## Generate ephemeral key pair with  name: bastionkey-${now}.${useThisPort}
            Write-Host "Creating ephemeral key pair"
            $now = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"
            $rand = Get-Random -Minimum 9001 -Maximum 9099
            $keyFile = New-OpuSshKeyFromKeygen -KeyBaseName ( -join ("bastionkey-", "${now}-${rand}"))

            Write-Host "Creating Manged SSH Session to ${TargetPort} at target"

            try {
                $bastionService = Get-OCIBastion -BastionId $BastionId  -WaitForLifecycleState Active -WaitIntervalSeconds 0 -ErrorAction Stop
            }
            catch {
                throw "Get-OCIBastion: $_"
            }    


            $maxSessionTtlInSeconds = $bastionService.MaxSessionTtlInSeconds

            ## Details of target
            $TargetResourceDetails = New-Object -TypeName 'Oci.BastionService.Models.CreateManagedSshSessionTargetResourceDetails'
            $TargetResourceDetails.TargetResourceOperatingSystemUserName = $OsUser
            $TargetResourceDetails.TargetResourceId = $TargetHostId

            ## Details of keyfile
            $keyDetails = New-Object -TypeName 'Oci.bastionService.Models.PublicKeyDetails'
            $keyDetails.PublicKeyContent = Get-Content "${keyFile}.pub"

            ## The actual session, name matches ephemeral key(s)
            $sessionDetails = New-Object -TypeName 'Oci.bastionService.Models.CreateSessionDetails'
            $sessionDetails.DisplayName = -join ("BastionSession-${now}-${rand}")
            $sessionDetails.SessionTtlInSeconds = $maxSessionTtlInSeconds
            $sessionDetails.BastionId = $BastionId
            $sessionDetails.KeyType = "PUB"
            $sessionDetails.TargetResourceDetails = $TargetResourceDetails
            $sessionDetails.KeyDetails = $keyDetails
    
            Write-Verbose "PayLoad"
            Write-Verbose (ConvertTo-Json $sessionDetails)

            ## This process needs more time than the regular 100*1000 ms that is default for OCI Posh modules
            ## There is a lot of stuff happening on the back-end
            try {
                $bastionSession = New-OciBastionSession -CreateSessionDetails $sessionDetails -ErrorAction Stop -TimeOutInMillis (5 * 60 * 1000)
            }
            catch {
                throw "New-OciBastionSession: $_"
            }
    
            Write-Host "Waiting for creation of bastion session to complete"
            try {
                $bastionSession = Get-OCIBastionSession -SessionId $bastionSession.Id -WaitForLifecycleState Active  -ErrorAction Stop 
            }
            catch {
                throw "Get-OCIBastionSession: $_"
            }

            ## Create ssh command argument
            $sshArgs = $bastionSession.SshMetadata["command"]

            ## First clean up any comments from Oracle(!)
            $hashPos = $sshArgs.IndexOf('#')
            if ($hashPos -gt 0) {
                $strlen = $sshArgs.length
                $sshArgs = $sshArgs.Remove($hashPos, $strlen - $hashPos)
            }

            ## Let's extract the data (user @ host) needed for the return object
            try {
                $pattern = '(?<user>[\w.-]+)@(?<host>[\w.-]+)'

                # Get all matches
                $allMatches = [regex]::Matches($sshArgs, $pattern)

                if ($allMatches.Count -ge 2) {
                    # The first match is the jump host (index 0)
                    $jumpUser = $allMatches[0].Groups['user'].Value
                    $jumpHost = $allMatches[0].Groups['host'].Value

                    # The last match is the target host
                    $targetUser = $allMatches[-1].Groups['user'].Value
                    $targetHost = $allMatches[-1].Groups['host'].Value
   
                    Write-Verbose "JumpUser:   $jumpUser, JumpHost: $jumpHost"
                    Write-Verbose "TargetUser: $targetUser, TargetHost: $targetHost"
                }
                else {
                    throw "Extract of user @ host failed: Not enough user@host patterns found to identify both jump and target."
                }
            }
            catch {
                throw "Extract of user @ host failed: $_"
            }

            ## Now create ssh_config string 
            if ($false -eq $IsProd) {
                if ($false -eq $IsWindows) {
                    $userKnownHostsFile = "`n  UserKnownHostsFile=/dev/null"
                }
                else {
                    $userKnownHostsFile = "`n  UserKnowHostFile=\\.\NUL"
                }

                $sshConfig = 
                "Host ${TargetHost}" + 
                "`n  Hostname ${TargetHost}" +
                "`n  User ${TargetUser}" +
                "`n  Port ${TargetPort}" +
                "`n  ServerAliveInterval 30" + 
                "`n  ServerAliveCountMax 4" +
                "`n  StrictHostKeyChecking no" + 
                $userKnownHostsFile +
                "`n  ProxyCommand ssh -i ${keyFile} -W %h:%p -p 22 ${JumpUser}@${JumpHost}"
                "`n"
            }
            else {
                $sshConfig = 
                "Host ${TargetHost}" + 
                "`n  Hostname ${TargetHost}" +
                "`n  User ${TargetUser}" +
                "`n  Port ${TargetPort}" +
                "`n  ServerAliveInterval 30" + 
                "`n  ServerAliveCountMax 4" +
                "`n  ProxyCommand ssh -i ${keyFile} -W %h:%p -p 22 ${JumpUser}@${JumpHost}"
                "`n"
            }

            ## Create return Object. remove 5min (300 secs) from estimated expiry
            $localBastionSession = [PSCustomObject]@{
                PSTypeName     = 'OpuManagedBastionSession.Object'
                BastionSession = $bastionSession
                KeyFile        = $keyFile
                JumpUser       = $jumpUser
                JumpHost       = $jumpHost
                TargetUser     = $targetUser
                TargetHost     = $targetHost
                TargetPort     = $TargetPort
                SshConfig      = $sshConfig
                SessionExpires = (Get-Date).AddSeconds($bastionSession.SessionTtlInSeconds - (5 * 60))
            }

            $localBastionSession
        }
        catch {
            ## Pass exception on back
            throw "New-OpuManagedSshSessionFull: $_"
        }
        finally {
            ## To Maximize possible clean ups, continue on error, fail silently
            $ErrorActionPreference = $userErrorActionPreference
        }
    }

    end {
        Write-Verbose "New-OpuManagedSshSessionFull: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
}
