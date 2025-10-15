
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
        [Parameter(HelpMessage='User to connect at target (opc)')]
        [String]$OsUser="opc"
    )

    begin {
        Write-Verbose "Starting function..."
    }

    process {
        ## Write-Verbose "Processing object: $($Name)"
        Write-Output "Hello World! $($BastionSession.LocalPort), ${OsUser}"
    }

    end {
        Write-Verbose "Completed function."
    }    
}
