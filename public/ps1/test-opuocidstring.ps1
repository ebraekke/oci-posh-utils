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
        [Parameter(Mandatory, HelpMessage='OCID string to validate')]
        [String]$OcidString,
        [Parameter(HelpMessage = 'Test if of type (N/A)')]
        [String]$IsOfType = 'N/A'
    )
    
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
            throw "Input string ${OcidString}: not a proper OCID string"
        }

        ## Now check if specific verification against object type was requested
        if ("N/A" -ne $IsOftype) {
            Write-Verbose "scope:"
            Write-Verbose $allMatches[0].Groups['scope'].Value
            if ($allMatches[0].Groups['scope'].Value -eq $IsOfType) {
                return
            } else {
                throw "Input string ${OcidString}: not of type ${IsOfType}"
            }

        } else {
            return
        }
    }
    catch {
        throw "Test-OcidString: $_"
    }
}
