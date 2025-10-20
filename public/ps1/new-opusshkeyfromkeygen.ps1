<#
.SYNOPSIS
Create a new SSH key file pair and return the name of the private file.

.DESCRIPTION
Creates a new ssh key file pair with 2048 bit length in the TEMP directory of the runtim platform.
Returns the name of the private key file. The public key file has the same name as the return value + ".pub". 
Ensures that file has "rw" for owner only (0600) if platform is *nix.
 
.PARAMETER KeyBaseName
Base name to create key file from. 

.EXAMPLE 
## Create key file pair successfully. 

❯ New-OpuSshKeyFromKeygen -KeyBaseName "thisone"

C:\Users\espenbr\AppData\Local\Temp/thisone

❯ dir C:\Users\espenbr\AppData\Local\Temp/thisone*

    Directory: C:\Users\espenbr\AppData\Local\Temp

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          20.10.2025    07:54           1831 thisone
-a---          20.10.2025    07:54            407 thisone.pub

.EXAMPLE 
## Failed attempt because ssh tools are not avilable. 

❯ New-OpuSshKeyFromKeygen -KeyBaseName "thisone"

New-OpuSshKeyFromKeygen: New-OpuSshKeyFromKeygen: Test-Executable: ssh not found

#>

function New-OpuSshKeyFromKeygen {
    param(
        [Parameter(Mandatory, HelpMessage='Use this base name')]
        [String]$KeyBaseName
    )

    try {
        ## START: generic section 
        $UserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        Write-Verbose "New-OpuSshKeyFromKeygen: begin"

        ## check that mandatory sw is installed    
        Test-OpuSshAvailable

        ## Generate name for temp SSH key file, tmpDir + base name supplied in parameter
        $tmpDir = Get-TempDir
        $keyFile = -join ("${tmpDir}/", $KeyBaseName) 

        try {
            if ($IsWindows) {
                ssh-keygen -t rsa -b 2048 -f $keyFile -q -N '' 
            }
            elseif ($IsLinux) {
                ssh-keygen -t rsa -b 2048 -f $keyFile -q -N '""' 
            }
            else {
                throw "Platform not supported ... how did you get here?"
            }
        }
        catch {
            throw "ssh-keygen: $_"
        }

        ## Make sure to set as rw for owner 
        if (($IsLinux) -or ($IsMacOS))  {
            chmod 0600 $sshKey
        }

        $keyFile

    } catch { 
        ## What else can we do? 
        Write-Error "New-OpuSshKeyFromKeygen: $_"
        return $false

    } finally {
        Write-Verbose "New-OpuSshKeyFromKeygen: end"

        ## START: generic section
        ## To Maximize possible clean ups, continue on error 
        $ErrorActionPreference = "Continue"

        ## More here? 

        ## Done, restore settings
        $ErrorActionPreference = $userErrorActionPreference
        ## END: generic section
    }
}
