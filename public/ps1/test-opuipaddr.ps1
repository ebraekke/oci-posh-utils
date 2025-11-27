<#
.SYNOPSIS
Tests that input string is a properly formated ip address.

.DESCRIPTION
Tests that the input is a proper private ip address in one of the three ranges:
- 10.0.0.0/8
- 172.16.0.0/12 
- 192.168.0.0/16

This is the defauot behavior controleld by parameter -AsPrivateOnly. 

If -AsPrivateOnly is set to $false, the cmdlet will ponly test if ip address is properly formed,
that is with 4 octets onbly containing numbers. 

The cmdlet throws an error if input (ip addres is) incorrect. 
There is no action if input is correct.

.EXAMPLE
## Test one ip as private that succeeds
> Test-OpuIpAddr -IpAddr "172.20.0.0"

.EXAMPLE 
## Test one ip addresss as private that fails
> Test-OpuIpAddr -IpAddr "172.10.0.0"
Exception: /Users/espenbr/GitHub/oci-posh-utils/public/ps1/test-opuipaddr.ps1:100
Line |
 100 |              throw "Test-OpuIpAddr: $_"
     |              ~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Test-OpuIpAddr: Input string 172.10.0.0: not a properly formed private Ipv4 address

.EXAMPLE
## Test a list of ip addresses ass private that succeeds
> $db_ips
10.0.1.77
10.0.1.80
10.0.1.210

> $db_ips | Test-OpuIpAddr

#>
function Test-OpuIpAddr {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'IP address to validate')]
        [String]$IpAddr,
        [Parameter(HelpMessage = 'Validate as private address only? ($true)')]
        [bool]$AsPrivateOnly = $true
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        Write-Verbose "Test-OpuIpAddr: begin"

        ## "Iterator" for comtrolling behavior with mulrpile input objects
        $globalCount = 0
    }

    process {
        try {
            Write-Verbose "IpAddr:"
            Write-Verbose $IpAddr

            if ($false -eq $AsPrivateOnly) {
                ## The formal CIDR notation for the corresponding regex patterns
                $cidrList = @(
                    '0.0.0.0/0'
                )
                $patternList = @(
                    '(?<oct1>[\d.-]+)\.(?<oct2>[\d.-]+)\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)$'
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
                    '(?<oct1>[1][0])\.(?<oct2>[\d.-]+)\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)$',
                    '(?<oct1>[1][7][2])\.(?<oct2>[1][6-9])\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)$',
                    '(?<oct1>[1][7][2])\.(?<oct2>[2][0-9])\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)$',
                    '(?<oct1>[1][7][2])\.(?<oct2>[3][0-1])\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)$',
                    '(?<oct1>[1][9][2])\.(?<oct2>[1][6][8])\.(?<oct3>[\d.-]+)\.(?<oct4>[\d.-]+)$'
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

    end {
        Write-Verbose "Test-OpuIpAddr: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    


}
