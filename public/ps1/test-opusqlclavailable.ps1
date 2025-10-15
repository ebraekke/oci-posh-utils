<#
.SYNOPSIS
Check if the required sqlcl is installed and available.

.DESCRIPTION
Used by session utils before engaging with the sqlcl. 
Can also be called independently.  

.EXAMPLE
## Test that sqlcl is installed is successful (no response)
Test-OpuSqlclAvailable

.EXAMPLE
## Test that Sqlcl is installed that fails.

Test-OpuSqlclAvailable
Exception: Test-Exeutable:sql not found
#>
function Test-OpuSqlclAvailable {
    Test-Executable -ExeName "sql"
}
