<#
.SYNOPSIS
Create a new SSH key file  and return the name.

.DESCRIPTION
...
 
.PARAMETER KeyBaseName
Base name to create key file from. 
This name will be padded with a "-" and a random number between 1 and 99999.

.EXAMPLE 
## Example 1.  

.EXAMPLE 
## Example 2

.EXAMPLE 
## Example 3
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

        ## Generate name for temp SSH key file, tmpDir + base name supplied in parameter + padding
        $paddingForName = Get-Random -Minimum 1 -Maximum 99999
        $tmpDir = Get-TempDir
        $keyFile = -join ("${tmpDir}/", $KeyBaseName, "-", "${paddingForName}") 

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
