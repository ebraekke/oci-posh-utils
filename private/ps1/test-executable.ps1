function Test-Executable {
    param(
        ## Name of executable to test
        [String]$ExeName
    )

    if ($null -eq $ExeName) {
        Throw "Test-Executable: -ExeName must be provided"
    }
    try {
        ## check that cmd exists
        Get-Command $ExeName -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Test-Executable: ${ExeName} not found"
    }
}
