<#
.SYNOPSIS
Create a port forwarding sesssion with OCI Bastion service.
Generate SSH key pair to be used for session.
Create the actual port forwarding SSH process.

Return an object to the caller:

$bastionSessionDescription = [PSCustomObject]@{
    PSTypeName = 'OpuBastionSession.Object'
    BastionSession = $bastionSession
    SShProcess = $sshProcess
    LocalPort = $useThisPort
    Target = "${TargetHost}:${TargetPort}"
    SessionExpires = <SessionExpireTimeInLocalTime>
}
        
.DESCRIPTION
Creates a port forwarding session with the OCI Bastion Service and the required SSH port forwarding process.
This combo will allow you to connect through the Bastion service via a local port and to your destination: $TargetHost:$TargetPort   
A path from the Bastion to the target is required.
The Bastion session inherits TTL from the Bastion (instance). 

.PARAMETER BastionId
OCID of Bastion with wich to create a session. 
 
.PARAMETER TargetHost
IP address of target host. 
   
.PARAMETER TargetPort
Port number at TargetHost to create a session to. 
Defaults to 22.  

.PARAMETER LocalPort
Local port to use for port forwarding. 
Defaults to 0, means that it will be randomly assigned.
Error thrown if requesting a port number lower than 1024.  

.PARAMETER WaitForConnectSeconds
How many seconds to wait for connection to be established before returning. 
Default 10.
Needed because it takes some time from the session is created 
until there is a path from the local port to the destination.
VPNs tend to make this even slower.

.EXAMPLE 
## Creating a forwarding session to the default port
> $bastion_session = New-OpuPortForwardingSessionFull -BastionId $bastion_ocid -TargetHost 10.0.1.249

Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.249:22
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting for creation of SSH tunnel to complete

> $bastion_session

BastionSession : Oci.BastionService.Models.Session
SShProcess     : System.Diagnostics.Process (Idle)
LocalPort      : 9084
Target         : 10.0.0.251:22
SessionExpires : 13.10.2025 14:26:05

.EXAMPLE 
## Creating a forwarding session to a mysql port

❯ $bastion_session = New-OpuPortForwardingSessionFull -BastionId $bastion_ocid -TargetHost 10.0.1.249 -TargetPort 3306

Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.249:3306
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting for creation of SSH tunnel to complete

❯ $bastion_session

BastionSession : Oci.BastionService.Models.Session
SShProcess     : System.Diagnostics.Process (Idle)
LocalPort      : 9043
Target         : 10.0.1.249:3306
SessionExpires : 16.10.2025 13:49:06
#>
function New-OpuPortForwardingSessionFull {
    param (
        [Parameter(Mandatory, HelpMessage='OCID of Bastion')]
        [String]$BastionId, 
        [Parameter(Mandatory, ValueFromPipeline=$true, HelpMessage='IP address of target host')]
        [String]$TargetHost,
        [Int32]$TargetPort=22,
        [Parameter(HelpMessage='Use this local port, 0 means assign')]
        [Int32]$LocalPort=0,
        [Parameter(HelpMessage='Seconds to wait before returing the session to the caller')]
        [Int32]$WaitForConnectSeconds=10
    )

    begin {
        ## START: generic section 
        $UserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        Write-Verbose "New-OpuPortForwardingSessionFull: begin"
    }

    process {
        try {
            ## Validate input
            if ((5 -gt $WaitForConnectSeconds) -or (60 -lt $WaitForConnectSeconds)) {
                throw "WaitForConnectSeconds is ${WaitForConnectSeconds}: must to be between 5 and 60!"
            }
            ## Verify LocalPort, assign to local variable to account for iteration over pipelined input
            if (0 -eq $LocalPort) {
                $useThisPort = Get-Random -Minimum 9001 -Maximum 9099
            }
            elseif ($LocalPort -lt 1024) {
                throw "LocalPort is ${LocalPort}: must be 1024 or greater!"
            } 
            else {
                $useThisPort = $LocalPort
            }

            ## check that mandatory sw is installed    
            Test-OpuSshAvailable

            ## Import modules
            Import-Module OCI.PSModules.Bastion
            $tmpDir = Get-TempDir
            $now = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"

            ## Generate ephemeral key pair in $tmpDir.  
            ## name: bastionkey-${now}.${useThisPort}
            ##
            ## Process will fail if another key with same name exists, in that case ..
            ##   TODO: decide what to do
            Write-Host "Creating ephemeral key pair"
            $keyFile = -join ("${tmpDir}/bastionkey-", "${now}-${useThisPort}")

            try {
                if ($IsWindows) {
                    ssh-keygen -t rsa -b 2048 -f $keyFile -q -N '' 
                }
                elseif ($IsLinux) {
                    ssh-keygen -t rsa -b 2048 -f $keyFile -q -N '""' 
                }
                else {
                    throw "Platform not supported ... how did you get here?"
                }
            }
            catch {
                throw "ssh-keygen: $_"
            }

            Write-Host "Creating Port Forwarding Session to ${TargetHost}:${TargetPort}"

            try {
                $bastionService = Get-OCIBastion -BastionId $BastionId  -WaitForLifecycleState Active -WaitIntervalSeconds 0 -ErrorAction Stop
            }
            catch {
                throw "Get-OCIBastion: $_"
            }    
            $maxSessionTtlInSeconds = $bastionService.MaxSessionTtlInSeconds

            ## Details of target
            $targetResourceDetails = New-Object -TypeName 'Oci.bastionService.Models.CreatePortForwardingSessionTargetResourceDetails'
            $targetResourceDetails.TargetResourcePrivateIpAddress = $TargetHost    
            $targetResourceDetails.TargetResourcePort = $TargetPort

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
            $sshArgs += " -o StrictHostKeyChecking=no"

            Write-Verbose "CONN: ssh ${sshArgs}"

            Write-Host "Creating SSH tunnel"
            try {
                if ($IsWindows) {
                    $sshProcess = Start-Process -FilePath "ssh" -ArgumentList $sshArgs -WindowStyle Hidden -PassThru -ErrorAction Stop
                }
                elseif ($IsLinux) {
                    $sshProcess = Start-Process -FilePath "ssh" -ArgumentList $sshArgs -PassThru -ErrorAction Stop
                }
            }
            catch {
                throw "Start-Process: $_"
            }

            ## TODO: Add "IsActive member to Object to determine if session was destroyed before expiration"?
            ##
            ## Create return Object
            $localBastionSession = [PSCustomObject]@{
                PSTypeName     = 'OpuBastionSession.Object'
                BastionSession = $bastionSession
                SShProcess     = $sshProcess
                LocalPort      = $useThisPort
                Target         = "${TargetHost}:${TargetPort}"
                SessionExpires = (Get-Date).AddSeconds($bastionSession.SessionTtlInSeconds)
            }

            Write-Host "Waiting for creation of SSH tunnel to complete"
            Start-Sleep -Seconds $WaitForConnectSeconds

            $localBastionSession
        }
        catch {
            ## Pass exception on back
            throw "New-OpuPortForwardingSessionFull: $_"
        }
        finally {

            ## To Maximize possible clean ups, continue on error, fail silently
            $ErrorActionPreference = 'SilentlyContinue' 
            Remove-Item $keyFile -ErrorAction SilentlyContinue
            Remove-Item "${keyFile}.pub" -ErrorAction SilentlyContinue
    
            ## Done, restore settings
            $ErrorActionPreference = $userErrorActionPreference
        }
    }

    end {
        Write-Verbose "New-OpuPortForwardingSessionFull: end"

        ## Done, restore settings
        $ErrorActionPreference = $userErrorActionPreference
    }    

}
