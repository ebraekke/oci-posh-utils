<#
.SYNOPSIS
Check if the required ssh tools (ssh and ssh-keygen) are installed and available.

.DESCRIPTION
Used by port forwarding utils before engaging with the ssh tools. 
Can also be called independently.  

.EXAMPLE
## Test that ssh is installed is successful. (no output)

Test-OpuSshAvailable


.EXAMPLE
## Test that ssh tools are installed that fails because of no ssh.

Test-OpuSshAvailable
Exception: Test-Executable: ssh not found

.EXAMPLE
## Test that ssh tools are installed that fails because of no ssh-keygen.

Test-OpuSshAvailable
Exception: Test-Executable: ssh-keygen not found
#>
function Test-OpuSshAvailable {
    Test-Executable -ExeName "ssh"
    Test-Executable -ExeName "ssh-keygen"        
}
