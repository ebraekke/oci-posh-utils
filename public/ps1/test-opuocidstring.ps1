<#
.SYNOPSIS
Tests that the input string is a properly formatted OCID reference. 

.DESCRIPTION
Tests that input string is a properly formated reference to a OCI resource or object. 
This reference is commonly refrred to as OCID. 

One example is the compartment string: 

ocid1.compartment.oc1..longcrypticuuidstyletexthereandlongcrypticuuidstyletextherex

Another example is this bastion string:

ocid1.bastion.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherex

A few resources do not have a region designator. This applies to compartment and user. 

Some possible resource type are: 
- compartment
- subnet
- vcn
- vaultsecret
- instance

.EXAMPLE
## Test one OCID string that matches requested resource type that succeeds
> Test-OpuOcidString -OcidString "ocid1.bastionsession.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherex" -IsOfType "bastionsession"

.EXAMPLE
## Test a list of OCID strings that matches the requested resource type that succeeds
> $db_ocids
ocid1.instance.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherex
ocid1.instance.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherey
ocid1.instance.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherez

> $db_ocids | Test-OpuOcidString -IsOfType instance

.EXAMPLE
## Test that list of OCID strings that matches the requested resource type that fails
> $db_ocids
ocid1.instance.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherex
ocid1.instance.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherey
ocid1.instance.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherez

> $db_ocids | Test-OpuOcidString -IsOfType vaultsecret
Exception: /Users/espenbr/GitHub/oci-posh-utils/public/ps1/test-opuocidstring.ps1:93
Line |
  93 |              throw "Test-OcidString: $_"
     |              ~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Test-OcidString: Input string
     | ocid1.instance.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherex: not of type vaultsecret

#>
function Test-OpuOcidString {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'OCID string to validate')]
        [String]$OcidString,
        [Parameter(HelpMessage = 'Test if of type (N/A)')]
        [String]$IsOfType = 'N/A'
    )
    
    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        Write-Verbose "Test-OpuOcidString: begin"

        ## "Iterator" for comtrolling behavior with mulrpile input objects
        $globalCount = 0
    }

    process {
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
                }
                else {
                    throw "Input string ${OcidString}: not of type ${IsOfType}"
                }

            }
            else {
                return
            }
        }
        catch {
            throw "Test-OcidString: $_"
        }
    }

    end {
        Write-Verbose "Test-OpuOcidString: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference
    }    
}

