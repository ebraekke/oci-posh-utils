<#
.SYNOPSIS
Create a new SSH key file from a secret and return the name.

.DESCRIPTION
Validates that ssh tools (ssh & ssh-keygen) are avilable.
Creates a local SSH key file from a secret stored in the OCI vault, pointed to by given SecretId. 
The file will be created in the temp area of the runtime platform and have the correct r/w  settings.
The file will be validated using ssh-keygen before returning.

There is no built-in book keeping for these downloaded secrets.
It is the responsibility of the caller to clean up
, as in removing file or destroying environment where file was downloaded. 

.PARAMETER SecretId
OCID of secret stored in vault that contains the ssh key. 
 
.PARAMETER KeyBaseName
Base name to create key file from. 
This name will be padded with a "-" and a random number between 1 and 99999.

.EXAMPLE 
## Successfully create a local file based on a valid ssh key.  

> New-OpuSshKeyFromSecret -SecretId $sshkey_ocid -KeyBaseName "MySecretSSHfile"
C:\Users\espenbr\AppData\Local\Temp/MySecretSSHfile-35391

.EXAMPLE 
## Try to create local file based on invalid secret  

❯ New-OpuSshKeyFromSecret -SecretId $bad_secret -KeyBaseName "MySecretSSHfile"

Load key "C:\\Users\\espenbr\\AppData\\Local\\Temp/MySecretSSHfile-34353": invalid format
New-OpuSshKeyFromSecret: New-SshKeyFromSecret: New-SshKeyFromSecret: SecretId points to a invalid private SSH key

.EXAMPLE 
## Try to create local file based on a non-existing secret  

❯ New-OpuSshKeyFromSecret -SecretId $nonexisting_secret -KeyBaseName "MySecretSSHfile"

New-OpuSshKeyFromSecret: New-SshKeyFromSecret: Get-OCISecretsSecretBundle: Error returned by Secrets Service. Http Status Code: 400. ServiceCode: InvalidParameter. OpcRequestId: oci-50BF380A546510B-202510160835/00881B9A54BA4396766268ACC7541FF1/C4E4672DD6470C82CDC905A636CA84B4. Message: secretId has an invalid format.
Operation Name: GetSecretBundle
TimeStamp: 2025-10-16T10:35:28.012Z
Client Version: Oracle-DotNetSDK/120.1.0 (Win32NT/10.0.26100.0; .NET 9.0.8)  Oracle-PowerShell/116.1.0
Request Endpoint: GET https://secrets.vaults.eu-frankfurt-1.oci.oraclecloud.com/20190301/secretbundles/abc?stage=CURRENT
For details on this operation's requirements, see https://docs.oracle.com/iaas/api/#/en/secretretrieval/20190301/SecretBundle/GetSecretBundle.
Get more information on a failing request by using the -Verbose or -Debug flags. See https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/powershellconcepts.htm#powershellconcepts_topic_logging
For more information about resolving this error, see https://docs.oracle.com/en-us/iaas/Content/API/References/apierrors.htm#apierrors_400__400_invalidparameter
If you are unable to resolve this Secrets issue, please contact Oracle support and provide them this full error message.
#>

function New-OpuSshKeyFromSecret {
    param(
        [Parameter(Mandatory, HelpMessage='OCID of secret holding the SSH key')]
        [String]$SecretId,
        [Parameter(Mandatory, HelpMessage='Use this base name')]
        [String]$KeyBaseName
    )

    try {
        ## START: generic section 
        $UserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        ## check that mandatory sw is installed    
        Test-OpuSshAvailable

        Write-Verbose "New-OpuSshKeyFromSecret: Getting the SSH key from the secrets vault"

        ## Get secret (read ssh key) from SecretId
        try {
            $secret = Get-OCISecretsSecretBundle -SecretId $SecretId -Stage Current -ErrorAction Stop
        }
        catch {
            throw "Get-OCISecretsSecretBundle: $_"
        }

        ## Generate name for temp SSH key file, tmpDir + base name supplied in parameter + padding
        $paddingForName = Get-Random -Minimum 1 -Maximum 99999
        $tmpDir = Get-TempDir
        $sshKey = -join("${tmpDir}/", $KeyBaseName, "-", "${paddingForName}") 

        ## Get Base64 encoded content and store in temp SSH key file  
        $sshKeyContent = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($secret.SecretBundleContent.Content))
        try {
            New-Item -Path $sshKey -Value $sshKeyContent -ErrorAction Stop | Out-Null
        }
        catch {
            throw "New-Item: $_"
        }

        ## Make sure to set as rw for owner 
        if (($IsLinux) -or ($IsMacOS))  {
            chmod 0600 $sshKey
        }

        Write-Verbose "New-OpuSshKeyFromSecret: Validating downloaded SSH key"
        ssh-keygen -y -f ($sshKey.Replace("~", $HOME)) | Out-Null
        if ($false -eq $?) {
            throw "New-OpuSshKeyFromSecret: SecretId points to a invalid private SSH key"
        }

        $sshKey

    } catch { 
        ## What else can we do? 
        Write-Error "New-SshKeyFromSecret: $_"
        return $false

    } finally {
        ## START: generic section
        ## To Maximize possible clean ups, continue on error 
        $ErrorActionPreference = "Continue"

        ## More here? 

        ## Done, restore settings
        $ErrorActionPreference = $userErrorActionPreference
        ## END: generic section
    }
}
