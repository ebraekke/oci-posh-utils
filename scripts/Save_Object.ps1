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

param(
    [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'Object to save')]
    [PSCustomObject]$SaveMe,
    [Parameter(Mandatory, HelpMessage = 'Name of directory to save object in')]
    [string]$DirectoryName
)

Write-Verbose "Save_Object.ps1: begin"

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
    if (-not (Test-Path -Path $DirectoryName)) {
        throw "Directory ${DirectoryName} does not exist"
    }

    ## Grab data from input object, format filename
    $typeNameStr = $SaveMe.TypeNameStr
    $id = $SaveMe.id
    $data = $SaveMe.Data
    $fileName = "${TypeNameStr}.${id}.json"

    ## Check that there are no periods '.' in Object's name ($TypeNameStr)
    ## Cannot have periods since it is used to convey meaning (or intent) 
    $parts = $typeNameStr -split '\.'
    if ($parts.length -gt 1) {
        throw "Unsupprted, TypeNameStr field contains periods""."": $typeNameStr"
    }

    Write-Verbose "TypeNameStr = ${typeNameStr}"
    Write-Verbose "id          = ${id}"

    ## Create output object
    try {
        $data_json = $data | ConvertTo-Json 
    }
    catch {
        throw "Converting to JSON: $_"
    }

    ## Now create file and populate
    try {
        New-Item -Path $DirectoryName -Name $fileName -ItemType "File" -Value $data_json -Force | Out-Null
    }
    catch {
        throw "Writing to file ${FileName}: $_"
    } 

    return $fileName
}
catch {
    ## What else can we do? 
    throw "Save_Object.ps1: $_"
}
finally {
    ## START: generic section

    ## To Maximize possible clean ups, continue on error 
    $ErrorActionPreference = "Continue"

    ## Done, restore settings
    $ErrorActionPreference = $userErrorActionPreference
    ## END: generic section

    Write-Verbose "Save_Object.ps1: end"
}
