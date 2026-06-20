<#
.SYNOPSIS
Check if the required openssl is installed and available.

.DESCRIPTION
Openssl is used to create fingerprint and validate api keys.  

.EXAMPLE
## Test that openssl is installed is successful. (no output)

> Test-OpuOpensslAvailable


.EXAMPLE
## Test that openssl is installed that fails.

> Test-OpuOpensslAvailable
Exception: Test-Executable: openssl not found

#>
function Test-OpuOpensslAvailable {
    Test-Executable -ExeName "openssl"
}
