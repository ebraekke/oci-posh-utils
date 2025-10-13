function Test-Executable {
    param(
        ## Name of executable to test
        [String]$ExeName
    )

    if ($null -eq $ExeName) {
        Throw "TestExecutable: -ExeName must be provided"
    }
    try {
        ## check that cmd exists
        Get-Command $ExeName -ErrorAction Stop | Out-Null
    }
    catch {
        throw "${ExeName} not found"
    }
}
