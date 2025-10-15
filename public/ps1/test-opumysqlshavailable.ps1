<#
.SYNOPSIS
Check if the required mysqlsh is installed and available.

.DESCRIPTION
Used by session utils before engaging with the mysqlsh. 
Can also be called independently.  

.EXAMPLE
## Test that mysqsh is installed is successful. (no response) 

Test-OpuMysqlshAvailable

.EXAMPLE
## Test that mysqlsh is installed that fails.

Test-OpuMysqlshAvailable
Exception: Test-Executable mysqlsh not found
#>
function Test-OpuMysqlshAvailable {
    Test-Executable -ExeName "mysqlsh"
}
