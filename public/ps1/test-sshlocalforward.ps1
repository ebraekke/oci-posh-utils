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
