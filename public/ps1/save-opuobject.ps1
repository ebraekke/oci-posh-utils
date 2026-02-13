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

function Save-OpuObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'Object to save')]
        [PSCustomObject]$SaveMe,
        [Parameter(Mandatory, HelpMessage = 'Name of directory to save object in')]
        [string]$Path
    )

    Write-Verbose "Save-OpuObject: begin"

    try {
        ## START: generic section
        $UserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 

        ## Check for "required" fields
        $attributesToTest = @("TypeNameStr", "id", "data")

        foreach ($attr in $attributesToTest) {
            if (-not ($SaveMe.psobject.Properties.Name -contains $attr)) {
                throw "Does not contain `"${attr}`""
            }
        }

        ## Check that directory exists 
        if (-not (Test-Path -Path $Path)) {
            throw "Directory ${Path} does not exist"
        }

        ## Grab data from input object, format filename
        $sep = '_X_'
        $typeNameStr = $SaveMe.TypeNameStr
        $id = $SaveMe.id
        $data = $SaveMe.Data
        $fileName = "${TypeNameStr}${sep}${id}${sep}.json"

        ## Check that there are no sepetrators in Object's name ($TypeNameStr)
        ## Cannot have periods since it is used to convey meaning (or intent) 
        $parts = $typeNameStr -split $sep
        if ($parts.length -gt 1) {
            throw "Unsupprted, TypeNameStr field contains seperator ""${sep}"": $typeNameStr"
        }

        Write-Verbose "TypeNameStr = ${typeNameStr}"
        Write-Verbose "id          = ${id}"

        ## Create output object
        try {
            $data_json = $data | ConvertTo-Json -Depth 100
        }
        catch {
            throw "Converting to JSON: $_"
        }

        ## Now create file and populate
        try {
            New-Item -Path $Path -Name $fileName -ItemType "File" -Value $data_json -Force | Out-Null
        }
        catch {
            throw "Writing to file ${FileName}: $_"
        } 

        return $fileName
    }
    catch {
        ## What else can we do? 
        throw "Save-OpuObject: $_"
    }
    finally {
        ## START: generic section

        ## To Maximize possible clean ups, continue on error 
        $ErrorActionPreference = "Continue"

        ## Done, restore settings
        $ErrorActionPreference = $userErrorActionPreference
        ## END: generic section

        Write-Verbose "Save-OpuObject: end"
    }
}