<#

-A for agent forward
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

#>

param(
    [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'Full Bastion Managed SSH Session Description Object')]
    [PSTypeName('OpuManagedSshSessionFull.Object')]$BastionSessionDescription,
    [Parameter(Mandatory, HelpMessage = 'Content of SSH key')]
    [String]$KeyContent,
    [Parameter(HelpMessage = 'Create local tunnel using this spec ($null)')]
    [String]$LocalPortDirective = $null,    
    [Parameter(HelpMessage = 'Is debug on ($false)')]
    [bool]$IsDebug = $false
)

function Test-SshLocalForward {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Directive
    )

    # Split the string by the colon delimiter
    $parts = $Directive -split ':'

    # Fail immediately if there are not exactly 3 parts
    if ($parts.Count -ne 3) { return $false }

    $localPort = $parts[0]
    $targetIp = $parts[1]
    $targetPort = $parts[2]

    # Helper scriptblock to validate port numbers (1-65535)
    $isValidPort = {
        param($port)
        if ($port -match '^\d+$') {
            $num = [int]$port
            return ($num -ge 1 -and $num -le 65535)
        }
        return $false
    }

    # Validate local port
    if (-not (&$isValidPort $localPort)) { return $false }

    # Validate target port
    if (-not (&$isValidPort $targetPort)) { return $false }

    # Validate target IP address using .NET parser
    $isIpValid = [ipaddress]::TryParse($targetIp, [ref]$null)
    if (-not $isIpValid) { return $false }

    # All checks passed
    return $true
}

Write-Verbose "Invoke_Ssh_Session.ps1: begin"

try {
    ## START: generic section
    $UserErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop" 

    Import-Module "${PSScriptRoot}/../oci-posh-utils.psd1"
    ## END: generic section

    ## Validate that ssh is indeed available
    Test-OpuSshAvailable

    ## validate input local port directive
    if (-not [string]::IsNullOrWhiteSpace($LocalPortDirective) ) {
        if (-not (Test-SshLocalForward $LocalPortDirective) ) {
            throw "Invalid Local port directive: ${LocalPortDirective}"
        }
    } 

    ## Write key to file
    $sshKey = New-TemporaryFile
    $KeyContent | Out-File -FilePath $sshKey.FullName

    ## Write SSH config to file
    $sshConfig = New-TemporaryFile
    $BastionSessionDescription.SshConfig | Out-File -FilePath $sshConfig.FullName

    ## Format all relevant parameters 
    $_sshKeyFullName = $sshkey.Fullname
    $_sshConfigFullName = $sshConfig.Fullname

    $_targetUser = $BastionSessionDescription.TargetUser
    $_targetHost = $BastionSessionDescription.TargetHost
    $_targetPort = $BastionSessionDescription.TargetPort

    if ([string]::IsNullOrWhiteSpace($LocalPortDirective)) {
        ssh -A -4 $_targetHost -p $_targetPort -l $_targetUser -F $_sshConfigFullName -i $_sshKeyFullName
    }
    else {
        ## TODO: change to -N ?
        ssh -L $LocalPortDirective -A -4 $_targetHost -p $_targetPort -l $_targetUser -F $_sshConfigFullName -i $_sshKeyFullName
    }

}
catch {
    ## What else can we do? 
    throw "Invoke_Ssh_Session.ps1: $_"
}
finally {
    ## START: generic section

    ## To Maximize possible clean ups, continue on error 
    $ErrorActionPreference = "Continue"
    
    ## Now remove module from memory
    ## Remove-Module oci-posh-utils

    ## Delete temp SSH key file and temp SSH config
    $ErrorActionPreference = 'SilentlyContinue' 

    if ($false -eq $IsDebug) {
        Write-Verbose "Removing tmp files"
        Remove-Item $sshKey -ErrorAction SilentlyContinue
        Remove-Item $sshConfig -ErrorAction SilentlyContinue
    }
    else {
        Write-Verbose "Key    : ${_sshKeyFullName}"
        Write-Verbose "Config : ${_sshConfigFullName}"

    }

    $ErrorActionPreference = "Continue"
    ## Done, restore settings
    $ErrorActionPreference = $userErrorActionPreference
    ## END: generic section

    Write-Verbose "Invoke_Ssh_Session.ps1: end"
}
