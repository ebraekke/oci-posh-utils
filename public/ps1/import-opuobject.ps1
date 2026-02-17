<#

$demo_object = [PSCustomObject]@{
    PSTypeName  = 'DemoSaveObject'
    TypeNameStr = "DemoSaveObject"
    id          = '1234'
    data        = [PSCustomObject]@{
        LocalPort      = 2222
        TargetHost     = '10.0.1.23'
        TargetPort     = 22
        SessionExpires = (Get-Date).AddSeconds(1000)
    }
}

#>

function Import-OpuObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = 'Full name of file containing object to load')]
        [string]$Path
    )
    begin {
        Write-Verbose "Import-OpuObject begin"
    }

    process {
        try {
            ## START: generic section
            $UserErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = "Stop" 
    
            if (-not (Test-Path -Path $Path )) {
                throw "File does not exist: ${Path}"
            }

            $FileName = Split-Path -Path $Path -Leaf    

            ## Grab data from input object's fiel name
            $sep = '_X_'
            $parts = $FileName -split $sep
            if ($parts.length -ne 3) {
                throw "Unsupported, Cannot decode filename ${FileName}"
            }

            $typeNameStr = $parts[0]
            $id = $parts[1]

            ## get data
            try {
                $data_json = Get-Content -Path $Path -raw  
            }
            catch {
                throw "Reading file: ${Path}: $_"
            }

            ## Convert to JSON
            try {
                $data = $data_json | ConvertFrom-Json -Depth 100
            }
            catch {
                throw "Converting file data to JSON from: ${Path}: $_"
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
            throw "Import-OpuObject $_"
        }
        finally {
            ## START: generic section

            ## To Maximize possible clean ups, continue on error 
            $ErrorActionPreference = "Continue"

            ## Done, restore settings
            $ErrorActionPreference = $userErrorActionPreference
            ## END: generic section
        }
    }

    end {
        Write-Verbose "Import-OpuObject end"
    }
}
