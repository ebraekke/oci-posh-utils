<#
<#
.SYNOPSIS
Create a dynamic port forwarding sesssion with OCI Bastion service.
Generate SSH key pair to be used for session.
Create the actual port forwarding SSH process.

Return an object to the caller:

$bastionSessionDescription = [PSCustomObject]@{
    PSTypeName = 'OpuDynPortBastionSession.Object'
    BastionSession = $bastionSession
    SShProcess = $sshProcess
    LocalPort = $useThisPort
    SessionExpires = <SessionExpireTimeInLocalTime>
}
        
.DESCRIPTION
Creates a dynamic port forwarding session with the OCI Bastion Service and the required SSH port forwarding process.
This combo will allow you to connect through the Bastion service via a local port and any destination reachable by the bastion service.  
A path from the Bastion to the target(s) is required.
The Bastion session inherits TTL from the Bastion (instance). 

.PARAMETER BastionId
OCID of Bastion with which to create a session.  
   
.PARAMETER LocalPort
Local port to use for port forwarding. 
Defaults to 0, means that it will be randomly assigned.
Error thrown if requesting a port number lower than 1024.
NOTE:
If a specific port is requested and the call is part of a pipeline,
each "instance" will receive a unique local port starting with value given.

.PARAMETER WaitForConnectSeconds
How many seconds to wait for connection to be established before returning. 
Default 10.
Needed because it takes some time from the session is created 
until there is a path from the local port to the destination.
VPNs tend to make this even slower.

.EXAMPLE 

.EXAMPLE 

.EXAMPLE 
#>
function New-OpuDynPortForwardingSessionFull {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = 'OCID of Bastion')]
        [String]$BastionId, 
        [Parameter(HelpMessage = 'Use this local port, 0 means assign')]
        [Int32]$LocalPort = 0,
        [Parameter(HelpMessage = 'Seconds to wait before returning the session to the caller')]
        [Int32]$WaitForConnectSeconds = 10
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        Write-Verbose "New-OpuDynPortForwardingSessionFull: begin"

        ## "Iterator" for assigning fixed port numbers 
        $globalCount = 0
    }

    process {
        try {
            ## Check input parameters
            Test-OpuOcidString -OcidString $BastionId -IsOfType "bastion"

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
                ## Add "position" of process/instance to accomodate for static assgnment on a list of IP addresses
                $useThisPort = $LocalPort + $globalCount
                $globalCount++
            }
            Write-Verbose "Will use local port: ${useThisPort} "

            ## check that mandatory sw is installed    
            Test-OpuSshAvailable

            ## Import modules
            Import-Module OCI.PSModules.Bastion

            ## Generate ephemeral key pair with  name: bastionkey-${now}.${useThisPort}
            Write-Host "Creating ephemeral key pair"
            $now = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"
            $keyFile = New-OpuSshKeyFromKeygen -KeyBaseName ( -join ("bastionkey-", "${now}-${useThisPort}"))

            try {
                $bastionService = Get-OCIBastion -BastionId $BastionId  -WaitForLifecycleState Active -WaitIntervalSeconds 0 -ErrorAction Stop
            }
            catch {
                throw "Get-OCIBastion: $_"
            }    

            Write-Host "Creating Dynamic Port Forwarding Session to ${bastionService.Name}"
            
            $maxSessionTtlInSeconds = $bastionService.MaxSessionTtlInSeconds

            $targetResourceDetails = New-Object -TypeName 'Oci.bastionService.Models.CreateDynamicPortForwardingSessionTargetResourceDetails'

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

            ## Supply relevant parameters. no host checking on localhost, high frequency of keep-alives
            $sshArgs = $sshArgs.replace("ssh", "-4")    ## avoid "bind: Cannot assign requested address" 
            $sshArgs = $sshArgs.replace("<privateKey>", $keyFile)
            $sshArgs = $sshArgs.replace("<localPort>", $useThisPort)
            $sshArgs += " -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=4 "

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

            ##
            ## Create return Object
            $localBastionSession = [PSCustomObject]@{
                PSTypeName     = 'OpuDynPortBastionSession.Object'
                BastionSession = $bastionSession
                SShProcess     = $sshProcess
                LocalPort      = $useThisPort
                SessionExpires = (Get-Date).AddSeconds($bastionSession.SessionTtlInSeconds - 300)
            }

            Write-Host "Waiting for creation of SSH tunnel to complete"
            Start-Sleep -Seconds $WaitForConnectSeconds

            $localBastionSession
        }
        catch {
            ## Pass exception on back
            throw "New-OpuDynPortForwardingSessionFull: $_"
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
        Write-Verbose "New-OpuDynPortForwardingSessionFull: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    

}
