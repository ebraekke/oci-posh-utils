<#
TODO: add comments

db_count                = "3"

# Input variables
set_name                = "dev"
deploy_to_zone          = "1"
compartment_ocid        = "ocid1.compartment.oc1..xyx"
vcn_ocid                = "ocid1.vcn.oc1.eu-frankfurt-1.xyz"
db_subnet_ocid          = "ocid1.subnet.oc1.eu-frankfurt-1.xyz"
app_subnet_ocid         = "ocid1.subnet.oc1.eu-frankfurt-1.xyz"
bastion_subnet_ocid     = "ocid1.subnet.oc1.eu-frankfurt-1.xyz"
vault_ocid              = "ocid1.vault.oc1.eu-frankfurt-1.xyz"
password_ocid           = "ocid1.vaultsecret.oc1.eu-frankfurt-1.xyz"
sshkey_ocid             = "ocid1.vaultsecret.oc1.eu-frankfurt-1.xyz"
db_image                = "ocid1.image.oc1.eu-frankfurt-1.xyz"
public_ssh_key_path     = "/Users/espenbr/OneDrive - Oracle Corporation/Documents/Security/id_ebraekke_no.pub"
 
# For provider 
region                  = "eu-frankfurt-1"
oci_cli_profile         = "nosefra"
tenancy_ocid            = "ocid1.tenancy.oc1..aaaaaaaaflf2uasr2shm5ag2yulp4gjy3aoqvwvvbcmvuk52fndnkps3byra"

#>
function Read-OpuTofuVariables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage='Full path to file containing OpenTofu variable assignment file')]
        [string[]]$FilePath
    )
   
    try {
        ## START: generic section 
        $userErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        Write-Verbose "Read-OpuTofuVariables: begin"

        $settings = @{} # Create an empty hashtable

        Get-Content -Path $filePath | ForEach-Object {
            # Skip empty lines or comments (optional)
            if (-not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith('#')) {
                # Split by the first colon or equals sign, take first part as key, rest as value
                $parts = $_ -split '[:=]', 2 
                $key = $parts[0].Trim()
                $value = $parts[1].Trim().Replace("`"", "")
                $settings[$key] = $value # Add to the hashtable
            }
        }

        # return hash
        $settings

    }
    catch { 
        ## What else can we do? 
        Write-Error "Read-OpuTofuVariables: $_"
        return $false

    }
    finally {
        Write-Verbose "Read-OpuTofuVariables: end"

        ## Done, restore settings
        $ErrorActionPreference = $userErrorActionPreference
    }
}
