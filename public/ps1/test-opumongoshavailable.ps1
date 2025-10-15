<#
.SYNOPSIS
Check if the required mongosh executable is installed and available.

.DESCRIPTION
Used by session utils before engaging with the mongosh. 
Can also be called independently.  

.EXAMPLE
## Test that mongosh is installed is successful (no response)
Test-OpuMongoshAvailable

.EXAMPLE
## Test that mongosh is installed that fails.

Test-OpuMongoshAvailable
Exception: Test-Executable: mongosh not found
#>
function Test-OpuMongoshAvailable {
    Test-Executable -ExeName "mongosh"
}
