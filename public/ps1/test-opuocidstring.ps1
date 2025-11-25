<#
TODO: Document why and how


ocid1.compartment.oc1..longcrypticuuidstyletexthereandlongcrypticuuidstyletextherex

compartment
subnet
vcn
vaultsecret
instance


#>
function Test-OpuOcidString {
    param(
        ## OCID object string to test
        [Parameter(HelpMessage = 'OCID string to validate')]
        [String]$OcidString,
        [Parameter(HelpMessage = 'Test if of type (N/A)')]
        [String]$IsOfType = 'N/A'
    )

    
    if ($null -eq $OcidString) {
        Throw "Test-OcidString: -OcidString must be provided"
    }
    try {
        ## Perform regex 
        $pattern = '(?<obj>[\w.-]+)\.(?<scope>[\w.-]+)\.(?<realm>[\w.-]+)\.(?<region>[\w.-]*)\.(?<uuid>[\w.-]+)'
        $allMatches = [regex]::Matches($OcidString, $pattern)
    
        Write-Verbose "OcidString:"
        Write-Verbose $OcidString
        Write-Verbose "Matches:" 
        Write-Verbose $allMatches.Count

        ## Need exact match
        if ($allMatches.Count -ne 1) {
            return $false
        }

        ## Now check if specific verification against object type was requested
        if ("N/A" -ne $IsOftype) {
            Write-Verbose "scope:"
            Write-Verbose $allMatches[0].Groups['scope'].Value
            if ($allMatches[0].Groups['scope'].Value -eq $IsOfType) {
                return $true
            } else {
                return $false
            }

        } else {
            return $true
        }
    }
    catch {
        throw "Test-OcidString: $_"
    }
}
