
<#
https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-pscustomobject?view=powershell-7.5

        $localBastionSession = [PSCustomObject]@{
            PSTypeName = 'OpuBastionSession.Object'
            BastionSession = $bastionSession
            SShProcess = $sshProcess
            LocalPort = $localPort
            Target = "${TargetHost}:${TargetPort}"
            SessionExpires = (Get-Date).AddSeconds($bastionSession.SessionTtlInSeconds)
        }

#>

function Test-OpuPipeLine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline=$true)]
        [PSTypeName('OpuBastionSession.Object')]$BastionSession,
        [Parameter(Mandatory, HelpMessage='OCID of secret holding the SSH key')]
        [String]$SecretId
    )

    begin {
        Write-Verbose "Test-OpuPipeLine: Starting function..."
    }

    process {
        $sshFile = New-SshKeyFromSecret -SecretId $SecretId -KeyBaseName $BastionSession.BastionSession.DisplayName

        Write-Output "Name of keyfile ${sshFile}"

#        Write-Output "Name of keyfile $($BastionSession.LocalPort), ${OsUser}"
    }

    end {
        Write-Verbose "Test-OpuPipeLine: Completed function."
    }    
}
