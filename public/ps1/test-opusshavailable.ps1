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
Exception: Assert-Executable: ssh not found

.EXAMPLE
## Test that ssh tools are installed that fails because of no ssh-keygen.

Test-OpuSshAvailable
Exception: Assert-Executable: ssh-keygen not found
#>
function Test-OpuSshAvailable {
    Assert-Executable -ExeName "ssh"
    Assert-Executable -ExeName "ssh-keygen"        
}
