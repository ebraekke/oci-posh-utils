
## Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\public\ps1 -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\private\ps1 -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue )

## Dot source the private functions
Foreach($import in @($Private))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import private function $($import.fullname): $_"
    }
}

## (1) Dot source the public functions
## (2) Make the public functions truly public. Side effect: makes private truly private
$exportedCount = 0
Foreach($import in @($Public))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import public function $($import.fullname): $_"
    }
    ## You **can** import modules that are not in scope/visible!
    ## So this will fail silently if there teh module has a different name than the file.
    Try
    {
        Export-ModuleMember -Function (Get-ChildItem $import).BaseName
        $exportedCount++
    }
    Catch
    {
        Write-Error -Message "Failed to \"export\" imported public function $($import.fullname): $_"
    }
}

if (0 -eq $exportedCount) {
    throw "No public functions, aborting"
}
