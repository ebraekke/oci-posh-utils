<#
TODO: Document why and how

Private: 
10.0.0.0/8

172.16.0.0/12 
172.16.0.0 - 172.31.255.255
[1][6-9]
[2][0-9]
[3][0-1]

192.168.0.0/16
#>
function Test-OpuIpAddr {
    param(
        [Parameter(Mandatory, HelpMessage = 'IP address to validate')]
        [String]$IpAddr,
        [Parameter(HelpMessage = 'Validate as private address only? ($true)')]
        [bool]$AsPrivateOnly = $true
    )

    try {
        Write-Verbose "IpAddr:"
        Write-Verbose $IpAddr

        if ($false -eq $AsPrivateOnly) {
            ## The formal CIDR notation for the corresponding regex patterns
            $cidrList = @(
                '0.0.0.0/0'
            )
            $patternList = @(
                '(?<oct1>[\d.-]+)\.(?<oct2>[\d.-]+)\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)'
            )
        }
        else {
            ## The formal CIDR notation for the corresponding regex patterns
            $cidrList = @(
                '10.0.0.0/8',
                '172.16.0.0/12',
                '172.16.0.0/12',
                '172.16.0.0/12',
                '192.168.0.0/16'
            )
            $patternList = @(
                '(?<oct1>[1][0])\.(?<oct2>[\d.-]+)\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)',
                '(?<oct1>[1][7][2])\.(?<oct2>[1][6-9])\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)',
                '(?<oct1>[1][7][2])\.(?<oct2>[2][0-9])\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)',
                '(?<oct1>[1][7][2])\.(?<oct2>[3][0-1])\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)',
                '(?<oct1>[1][9][2])\.(?<oct2>[1][6][8])\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)'
            )
        }

        ## Iterate and apply regex
        $loopCnt = 0
        foreach ($pattern in $patternList) {
            $allMatches = [regex]::Matches($IpAddr, $pattern)

            Write-Verbose "Validating:"
            Write-verbose $cidrList[$loopCnt]
            Write-Verbose $allMatches.Count

            if ($allMatches.Count -eq 1) {
                return;
            }
            $loopCnt++
        }

        ## No matches, let's throw an error for the "public" case
        if ($false -eq $AsPrivateOnly) {
            throw "Input string ${IpAddr}: not a properly formed Ipv4 address"
        }

        ## Throw error for the regular case, as in private ip
        throw "Input string ${IpAddr}: not a properly formed private Ipv4 address"

    }
    catch {
        throw "Test-OpuIpAddr: $_"
    }
}
