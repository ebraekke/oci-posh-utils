<#
.SYNOPSIS
Check if the required ssh tools (ssh and ssh-keygen) are installed and available.

.DESCRIPTION
Used by port forwarding utils before engaging with the ssh tools. 
Can also be called independently.  

.EXAMPLE
## Test that ssh is installed is successful. (no output)

Test-OpuSshAvailability


.EXAMPLE
## Test that ssh tools are installed that fails because of no ssh.

Test-OpuSshAvailability
Exception: ssh not found

.EXAMPLE
## Test that ssh tools are installed that fails because of no ssh-keygen.

Test-OpuSshAvailability
Exception: ssh-keygen not found
#>
function Test-OpuSshAvailable {
    Test-Executable -ExeName "ssh"
    Test-Executable -ExeName "ssh-keygen"        
}
