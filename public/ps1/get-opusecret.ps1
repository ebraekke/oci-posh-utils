<#
.SYNOPSIS
Get a secret from the OCI vault based on secret id.

.DESCRIPTION
Get secret from vault based on supplied ocid.
Will return as Base64 encoded or as plain text depending on parameter AsPlainText

.PARAMETER SecretId
OCID of secret stored in teh vault. 

.PARAMETER AsPlainText
Boolean that determines if secret is returned as plain text or as base6 encoded.
Default is $true. 

.EXAMPLE
## Successfully getting a secret into a local variable. Return value is plain text. 
> my_secret = Get-OpuSecret -SecretId $sshkey_ocid

.EXAMPLE
## Successfully getting a secret into a local variable. Return value is base64 encode. 
> my_secret = Get-OpuSecret -SecretId $sshkey_ocid -AsPlainTExt $false

.EXAMPLE 
## Trying retrieve a non existing secret.
> $my_secret = Get-OpuSecret -SecretId $invalid_secret_id
Exception: C:\Users\espenbr\GitHub\oci-posh-utils\public\ps1\get-opusecret.ps1:59
Line |
  59 |          throw "Get-OpuSecret: $_"
     |          ~~~~~~~~~~~~~~~~~~~~~~~~~
     | Get-OpuSecret: Get-OCISecretsSecretBundle: Error returned by Secrets Service. Http Status Code: 400. ServiceCode:
     | InvalidParameter. OpcRequestId:
     | oci-B54332F8E22BB81-202510151512/28934668C4BB20C6C3B0DCADBE4F824A/67163ED120363B7E54102618DD239CD0. Message: secretId has an
     | invalid format. Operation Name: GetSecretBundle TimeStamp: 2025-10-15T17:12:51.089Z Client Version: Oracle-DotNetSDK/120.1.0
     | (Win32NT/10.0.26100.0; .NET 9.0.8)  Oracle-PowerShell/116.1.0  Request Endpoint: GET
     | https://secrets.vaults.eu-frankfurt-1.oci.oraclecloud.com/20190301/secretbundles/123abc?stage=CURRENT For details on this
     | operation's requirements, see https://docs.oracle.com/iaas/api/#/en/secretretrieval/20190301/SecretBundle/GetSecretBundle.
     | Get more information on a failing request by using the -Verbose or -Debug flags. See
     | https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/powershellconcepts.htm#powershellconcepts_topic_logging For more
     | information about resolving this error, see
     | https://docs.oracle.com/en-us/iaas/Content/API/References/apierrors.htm#apierrors_400__400_invalidparameter If you are unable
     | to resolve this Secrets issue, please contact Oracle support and provide them this full error message.
#>
function Get-OpuSecret {
    param (
        [Parameter(Mandatory, HelpMessage='OCID of secret to retrieve')]
        [String]$SecretId,
        [Parameter(HelpMessage='Return as plaintex ($true)')]
        [bool]$AsPlainText=$true
    )

    $userErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop" 
    Write-Verbose "Get-OpuSecret: begin"

    try {
        ## Import the modules needed here
        Import-Module OCI.PSModules.Secrets


        ## Get secret bundle based on ocid 
        try {
            $secretBundle = Get-OCISecretsSecretBundle -SecretId $SecretId -Stage Current -ErrorAction Stop
        }
        catch {
            throw "Get-OCISecretsSecretBundle: $_"
        }

        $secretBase64 = $secretBundle.SecretBundleContent.Content
 
        if ($true -eq $AsPlainText) {
            ## convert to plaintext
            $secret = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($secretBase64))
        } else {
            ## return as base64 encoded
            $secret = $secretBase64
        }

        ## return secret
        $secret

    } catch {
        ## Pass exception on back
        throw "Get-OpuSecret: $_"
    } finally {
        Write-Verbose "Get-OpuSecret: end"

        ## To Maximize possible clean ups, continue on error 
        $ErrorActionPreference = "Continue"
    
        ## Done, restore settings
        $ErrorActionPreference = $userErrorActionPreference
    }

}
