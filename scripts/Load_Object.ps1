<#

#>

param(
    [Parameter(Mandatory, HelpMessage = 'Full name of fiel containign object to load')]
    [string]$FileName
)

Write-Verbose "Load_Object.ps1: begin"

try {
    ## START: generic section
    $UserErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop" 
    
    if (-not (Test-Path -Path $FileName )) {
        throw "File does not exist: ${FileName}"
    }

    $localFileName = Split-Path -Path $FileName -Leaf    

    ## Grab data from input object's fiel name
    $sep = '_X_'
    $parts = $localFileName -split $sep
    if ($parts.length -ne 3) {
        throw "Unsupported, Cannot decode filename ${localFileName}"
    }

    $typeNameStr = $parts[0]
    $id = $parts[1]

    ## get data
    try {
        $data_json = Get-Content -Path $FileName -raw  
    }
    catch {
        throw "Reading file: ${FileName}: $_"
    }

    ## Convert to JSON
    try {
        $data = $data_json | ConvertFrom-Json -Depth 100
    }
    catch {
        throw "Converting file data to JSON from: ${FileName}: $_"
    }

    $returnObject = [PSCustomObject]@{
        PSTypeName  = $typeNameStr
        TypeNameStr = $typeNameStr
        id          = $id
        data        = $data
    }

    $returnObject
}

catch {
    ## What else can we do? 
    throw "Load_Object.ps1: $_"
}
finally {
    ## START: generic section

    ## To Maximize possible clean ups, continue on error 
    $ErrorActionPreference = "Continue"

    ## Done, restore settings
    $ErrorActionPreference = $userErrorActionPreference
    ## END: generic section

    Write-Verbose "Load_Object.ps1: end"
}
