<#
.SYNOPSIS
Check if the required mongosh executable is installed and available.

.DESCRIPTION
Used by session utils before engaging with the mongosh. 
Can also be called independently.  

.EXAMPLE
## Test that mongosh is installed is successful (no response)
Test-OpuMongoshAvailability

.EXAMPLE
## Test that mongosh is installed that fails.

Test-OpuMongoshAvailability
Exception: mongosh not found
#>
function Test-OpuMongoshAvailable {
    Test-Executable -ExeName "mongosh"
}
