<#
Return an object to the caller:

$bastionSessionDescription = [PSCustomObject]@{
    PSTypeName     = 'OpuPortForwardingSession.Object'
    TypeNameStr    = "OpuPortForwardingSession.Object"
    LifecycleState = "Active"
    BastionSession = $bastionSession
    TargetHost.    = $TargetHost
    TargetPort     = $TargetPort
    KeyFileContent = <Content of ssh key file>
    SessionExpires = <SessionExpireTimeInLocalTime>
}

if RandomId is 0, then generate between 9001 and 9999
#>
function New-OpuPortForwardingSession {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'IP address of target host')]
        [String]$TargetHost,
        [Parameter(Mandatory, HelpMessage = 'OCID of Bastion')]
        [String]$BastionId, 
        [Int32]$TargetPort = 22,
        [Int32]$RandomId = 0
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        Write-Verbose "New-OpuPortForwardingSession: begin"

        ## "Iterator" for assigning fixed port numbers 
        $globalCount = 0
    }

    process {
        try {
            ## Check input parameters
            Test-OpuOcidString -OcidString $BastionId -IsOfType "bastion"
            Test-OpuIpAddr -IpAddr $TargetHost

            ## check that mandatory sw is installed    
            Test-OpuSshAvailable

            ## Import modules
            Import-Module OCI.PSModules.Bastion

            ## Set Random to value in range 9001 to 9999 if not specified (=0)
            if (0 -eq $RandomId) {
                $RandomId = Get-Random -Minimum 9001 -Maximum 9099
            }

            ## Generate ephemeral key pair with  name: bastionkey-${now}-${RandomId}
            Write-Host "Creating ephemeral key pair"
            $now = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"
            $keyFile = New-OpuSshKeyFromKeygen -KeyBaseName ( -join ("bastionkey-", "${now}-${RandomId}"))
            $keyFileContent = Get-Content -path $keyFile -raw

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
            $keyDetails.PublicKeyContent = Get-Content "${keyFile}.pub" -Raw

            ## The actual session, name matches ephemeral key(s)
            $sessionDetails = New-Object -TypeName 'Oci.bastionService.Models.CreateSessionDetails'
            $sessionDetails.DisplayName = -join ("BastionSession-${now}-${RandomId}")
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

            ## Create return Object. remove 5min (300 secs) from estimated expiry
            $localBastionSession = [PSCustomObject]@{
                PSTypeName     = 'OpuPortForwardingSession.Object'
                TypeNameStr    = "OpuPortForwardingSession.Object"
                LifecycleState = "Active"
                BastionSession = $bastionSession
                TargetHost     = $TargetHost
                TargetPort     = $TargetPort
                KeyFileContent = $keyFileContent
                SessionExpires = (Get-Date).AddSeconds($bastionSession.SessionTtlInSeconds - (5 * 60))
            }

            $localBastionSession
        }
        catch {
            ## Pass exception on back
            throw "New-OpuPortForwardingSession: $_"
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
        Write-Verbose "New-OpuPortForwardingSession: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    

}
