
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
    ## NOTE: 
    ## You **can** export functions that are not in scope/visible (without error being thrown)!
    ## So this "bootstrapping" will fail silently 
    ##   (1) if the function has a different name than the (base part of the) file.
    ##   OR
    ##   (2) the file exists, but is is empty.
    ## Hence, the DEBUG in the block below. 
    ## If you are experiencing any problems, 
    ## validate DEBUG output versus the output of "Get-Command -Module oci-posh-utils"
    Try
    {
        $exportThis = (Get-ChildItem $import).BaseName
        Export-ModuleMember -Function $exportThis
        Out-Host -InputObject "DEBUG: Exported helper function ${exportThis}"
        $exportedCount++
    }
    Catch
    {
        Write-Error -Message "Failed to \"export\" imported public function $($exportThis): $_"
    }
}

if (0 -eq $exportedCount) {
    throw "No public functions, aborting"
}
