<#
.SYNOPSIS
Check if the required ssh tools (ssh and ssh-keygen) are installed and available.

.DESCRIPTION
Used by port forwarding utils before engaging with the ssh tools. 
Can also be called independently.  

.EXAMPLE
## Assert that ssh is installed is successful. (no output)

Assert-OpuSshAvailable


.EXAMPLE
## Assert that ssh tools are installed that fails because of no ssh.

Assert-OpuSshAvailable
Exception: Assert-Executable: ssh not found

.EXAMPLE
## Assert that ssh tools are installed that fails because of no ssh-keygen.

Assert-OpuSshAvailable
Exception: Assert-Executable: ssh-keygen not found
#>
function Assert-OpuSshAvailable {
    Assert-Executable -ExeName "ssh"
    Assert-Executable -ExeName "ssh-keygen"        
}
