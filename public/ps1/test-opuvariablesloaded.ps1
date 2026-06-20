<#
TODO: add comments


#>
function Test-OpuVariablesLoaded {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = 'Table containing variables to validate presence of')]
        [string[]]$VariablesNeeded,
        [Parameter(Mandatory, HelpMessage = 'Hash containing all variables with values that has been loaded')]
        [hashtable]$Variablesloaded
    )
   
    try {
        ## START: generic section 
        $userErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        Write-Verbose "Test-OpuVariablesLoaded: begin"

        foreach ($key in $VariablesNeeded) {
            Write-Verbose "Testing ${key}"
            if ([string]::IsNullOrWhiteSpace($VariablesLoaded[$key])) {
                throw "Value for `"${key}`" not defined in VariablesLoaded"
            }
        }
    }
    catch { 
        ## What else can we do? 
        Write-Error "Test-OpuVariablesLoaded: $_"
        return $false

    }
    finally {
        Write-Verbose "Test-OpuVariablesLoaded: end"

        ## Done, restore settings
        $ErrorActionPreference = $userErrorActionPreference
    }
}
