function Assert-Executable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ExeName
    )

    if (-not (Get-Command $ExeName -ErrorAction SilentlyContinue)) {
        throw "Required executable '$ExeName' was not found on PATH."
    }
}
