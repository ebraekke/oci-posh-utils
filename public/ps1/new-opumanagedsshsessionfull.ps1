<#
Creating Manged SSH Session to 10.0.1.159:22
Exception: /Users/espenbr/GitHub/oci-posh-utils/public/ps1/new-opumanagedsshsessionfull.ps1:138
Line |
 138 |              throw "New-OpuManagedSshSessionFull: $_"
     |              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | New-OpuManagedSshSessionFull: New-OciBastionSession: Error returned by Bastion Service. Http Status Code: 400. ServiceCode:
     | InvalidParameter. OpcRequestId:
     | oci-FA19ED38DB7A00F-202511041310/C9EADD20D7EDF6875AFB0969465241AB/FFA107133394540982660DF159673420. Message: You must
     | provide a valid target compute instance OCID (targetResourceId) to create a managed SSH session. The instance OCID must be
     | a string value and cannot exceed 255 characters. Operation Name: CreateSession TimeStamp: 2025-11-04T14:10:50.326Z Client
     | Version: Oracle-DotNetSDK/122.0.0 (Unix/15.7.1; .NET 9.0.10)  Oracle-PowerShell/118.0.0  Request Endpoint: POST
     | https://bastion.eu-frankfurt-1.oci.oraclecloud.com/20210331/sessions For details on this operation's requirements, see
     | https://docs.oracle.com/iaas/api/#/en/bastion/20210331/Session/CreateSession. Get more information on a failing request by
     | using the -Verbose or -Debug flags. See
     | https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/powershellconcepts.htm#powershellconcepts_topic_logging For more
     | information about resolving this error, see
     | https://docs.oracle.com/en-us/iaas/Content/API/References/apierrors.htm#apierrors_400__400_invalidparameter If you are
     | unable to resolve this Bastion issue, please contact Oracle support and provide them this full error message.

Need to publish ocids of hosts as weel ass IPs when creating
#>
function New-OpuManagedSshSessionFull {
    param (
        [Parameter(Mandatory, HelpMessage='OCID of Bastion')]
        [String]$BastionId, 
        [Parameter(Mandatory, ValueFromPipeline=$true, HelpMessage='IP address of target host')]
        [String]$TargetHost,
        [Int32]$TargetPort=22,
        [Parameter(HelpMessage='Seconds to wait before returing the session to the caller')]
        [Int32]$WaitForConnectSeconds=10
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

            ## Validate input
            if ((5 -gt $WaitForConnectSeconds) -or (60 -lt $WaitForConnectSeconds)) {
                throw "WaitForConnectSeconds is ${WaitForConnectSeconds}: must to be between 5 and 60!"
            }

            ## Import modules
            Import-Module OCI.PSModules.Bastion

            ## Generate ephemeral key pair with  name: bastionkey-${now}.${useThisPort}
            Write-Host "Creating ephemeral key pair"
            $now = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"
            $rand = Get-Random -Minimum 9001 -Maximum 9099
            $keyFile= New-OpuSshKeyFromKeygen -KeyBaseName (-join ("bastionkey-", "${now}-${rand}"))

            Write-Host "Creating Manged SSH Session to ${TargetHost}:${TargetPort}"

            try {
                $bastionService = Get-OCIBastion -BastionId $BastionId  -WaitForLifecycleState Active -WaitIntervalSeconds 0 -ErrorAction Stop
            }
            catch {
                throw "Get-OCIBastion: $_"
            }    
            $maxSessionTtlInSeconds = $bastionService.MaxSessionTtlInSeconds

            ## Details of target
            $TargetResourceDetails                                        = New-Object -TypeName 'Oci.BastionService.Models.CreateManagedSshSessionTargetResourceDetails'
            $TargetResourceDetails.TargetResourceOperatingSystemUserName  = "opc"
            $TargetResourceDetails.TargetResourcePrivateIpAddress         = $TargetHost

            ## Details of keyfile
            $keyDetails = New-Object -TypeName 'Oci.bastionService.Models.PublicKeyDetails'
            $keyDetails.PublicKeyContent = Get-Content "${keyFile}.pub"

            ## The actual session, name matches ephemeral key(s)
            $sessionDetails = New-Object -TypeName 'Oci.bastionService.Models.CreateSessionDetails'
            $sessionDetails.DisplayName = -join ("BastionSession-${now}-${useThisPort}")
            $sessionDetails.SessionTtlInSeconds = $maxSessionTtlInSeconds
            $sessionDetails.BastionId = $BastionId
            $sessionDetails.KeyType = "PUB"
            $sessionDetails.TargetResourceDetails = $targetResourceDetails
            $sessionDetails.KeyDetails = $keyDetails
    
            try {
                $bastionSession = New-OciBastionSession -CreateSessionDetails $sessionDetails -ErrorAction Stop
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

            ## Supply relevant parameters
            $sshArgs = $sshArgs.replace("ssh", "-4")    ## avoid "bind: Cannot assign requested address" 
            $sshArgs = $sshArgs.replace("<privateKey>", $keyFile)
            $sshArgs = $sshArgs.replace("<localPort>", $useThisPort)
            $sshArgs += " -o StrictHostKeyChecking=no -o ServerAliveInterval=120 -o ServerAliveCountMax=90 "

            Write-Verbose "CONN: ssh ${sshArgs}"

            Write-Host "Creating SSH tunnel"
            try {
                if ($IsWindows) {
                    $sshProcess = Start-Process -FilePath "ssh" -ArgumentList $sshArgs -WindowStyle Hidden -PassThru -ErrorAction Stop
                }
                elseif ($IsLinux) {
                    $sshProcess = Start-Process -FilePath "ssh" -ArgumentList $sshArgs -PassThru -ErrorAction Stop
                }
                elseif ($IsMacOS) {
                    $sshProcess = Start-Process -FilePath "ssh" -ArgumentList $sshArgs -PassThru -ErrorAction Stop
                } 
                else {
                    throw "Unkown OS,  how did you get here?"
                }
            }
            catch {
                throw "Start-Process: $_"
            }

            ## Create return Object
            $localBastionSession = [PSCustomObject]@{
                PSTypeName     = 'OpuManagedBastionSession.Object'
                BastionSession = $bastionSession
                SShProcess     = $sshProcess
                Target         = "${TargetHost}:${TargetPort}"
                SessionExpires = (Get-Date).AddSeconds($bastionSession.SessionTtlInSeconds)
            }

            $localBastionSession
        }
        catch {
            ## Pass exception on back
            throw "New-OpuManagedSshSessionFull: $_"
        }
        finally {
            ## To Maximize possible clean ups, continue on error, fail silently
            $userErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue' 
            Remove-Item $keyFile -ErrorAction SilentlyContinue
            Remove-Item "${keyFile}.pub" -ErrorAction SilentlyContinue
            $ErrorActionPreference = $userErrorActionPreference
        }
    }

    end {
        Write-Verbose "New-OpuManagedSshSessionFull: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
}
