<#
.SYNOPSIS
Create a dynamic port forwarding sesssion with OCI Bastion service.
Generate SSH key pair to be used for session.
Create the actual port forwarding SSH process.

Return an object to the caller:

$bastionSessionDescription = [PSCustomObject]@{
    PSTypeName = 'OpuDynPortForwardingSession.Object'
    TypeNameStr = "OpuDynPortForwardingSession.Object"
    LifecycleState = "Active"
    BastionSession = $bastionSession
    KeyFileContent = <Content of ssh key file>
    SessionExpires = <SessionExpireTimeInLocalTime>
}
        
#>
function New-OpuDynPortForwardingSession {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = 'OCID of Bastion')]
        [String]$BastionId, 
        [Int32]$RandomId = 0
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        Write-Verbose "New-OpuDynPortForwardingSession: begin"

        ## "Iterator" for assigning fixed port numbers 
        $globalCount = 0
    }

    process {
        try {
            ## Check input parameters
            Test-OpuOcidString -OcidString $BastionId -IsOfType "bastion"

            ## Validate input
            Write-Verbose "Will use this RanndomId: ${RandomId} "

            ## check that mandatory sw is installed    
            Test-OpuSshAvailable

            ## Import modules
            Import-Module OCI.PSModules.Bastion

            ## Set Random to value in range 9001 to 9999 if not specified (=0)
            if (0 -eq $RandomId) {
                $RandomId = Get-Random -Minimum 9001 -Maximum 9099
            }

            ## Generate ephemeral key pair with  name: bastionkey-${now}.${useThisPort}
            Write-Host "Creating ephemeral key pair"
            $now = Get-Date -Format "yyyy_MM_dd_HH_mm_ss"
            $keyFile = New-OpuSshKeyFromKeygen -KeyBaseName ( -join ("bastionkey-", "${now}-${RandomId}"))
            $keyFileContent = Get-Content -path $keyFile -raw

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

            ##
            ## Create return Object, pad eith 5 mins on estimated expiry just for safety
            $localBastionSession = [PSCustomObject]@{
                PSTypeName     = 'OpuDynPortForwardingSession.Object'
                TypeNameStr    = "OpuDynPortForwardingSession.Object"
                LifecycleState = "Active"
                BastionSession = $bastionSession
                KeyFileContent = $keyFileContent
                SessionExpires = (Get-Date).AddSeconds($bastionSession.SessionTtlInSeconds - 300)
            }

            $localBastionSession
        }
        catch {
            ## Pass exception on back
            throw "New-OpuDynPortForwardingSession: $_"
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
        Write-Verbose "New-OpuDynPortForwardingSession: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    

}
