<#
.SYNOPSIS
Create an Autonomous Database connection object (hash) based on a ConnnectionId.

Return an object to the caller:

$adbConnection = [PSCustomObject]@{
    UserName = $connection.UserName
    PasswordBase64 = $secret.SecretBundleContent.Content
    TargetHost = $adb.PrivateEndpointip
    TargetPort = 1521 or 27071
    ConnStr = $connStr
}

Connection object described in general here: 
https://docs.oracle.com/en-us/iaas/tools/dotnet/101.3.0/api/Oci.DatabasetoolsService.Models.html

Specifics here:
https://docs.oracle.com/en-us/iaas/tools/dotnet/101.3.0/api/Oci.DatabasetoolsService.Models.DatabaseToolsConnectionOracleDatabase.html


.DESCRIPTION
By following the references on the connection object collect from both DB object and Secret in Vault:
* Username
* Base64 encoded password
* Private ip of service
* Port of service, that is 1521 if a regular connection 27071 if a momgdbapi connection
* connection string or tns alias

.PARAMETER ConnectionId
OCID of connection containing the details about the database  and user. 

.PARAMETER AsMongodbApi
Return connection object as a Mongoapi compatible object. 
This results in validation of the dbToolsDetails array.  
There neds to be one entry with value of ["MongodbApi", "True"] in this collection for the process to proceed.  
Also, port number 27017 is returned as opposed to the default of 1521. 

.EXAMPLE 

#>

function New-OpuAdbConnection {
    param (
        [Parameter(Mandatory, HelpMessage='OCID of connection')]
        [String]$ConnectionId,
        [Parameter(HelpMessage='Return as MongodbApi connection')]
        [bool]$AsMongodbApi=$false
    )
    $userErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop" 

    try {
        ## Validate input 
        Test-OpuOcidString -OcidString $ConnectionId -IsOfType "databasetoolsconnection"

        ## Import the modules needed here
        Import-Module OCI.PSModules.Database
        Import-Module OCI.PSModules.Databasetools
        Import-Module OCI.PSModules.Secrets
    
        Write-Host "Getting details from connection"

        ## Grab main handle, ensure it is in correct lifecycle state and that it points to an ADB
        try {
            $connection = Get-OCIDatabasetoolsconnection -DatabaseToolsconnectionId $connectionId -WaitForLifecycleState Active -WaitIntervalSeconds 0 -ErrorAction Stop
        }
        catch {
            throw "Get-OCIDatabasetoolsconnection: $_"
        }
        if ("Autonomousdatabase" -ne $connection.RelatedResource.EntityType) {
            throw "Connection does not point to an Autonomous database"
        }
        
        ## Grab adb info based on conn handle, ensure it is in correct lifecycle state
        try {
            $adb = Get-OCIDatabaseAutonomousDatabase -AutonomousDatabaseId $connection.RelatedResource.Identifier -WaitForLifecycleState Available -WaitIntervalSeconds 0 -ErrorAction Stop
        }
        catch {
            throw "Get-OCIDatabaseAutonomousDatabase: $_"
        }
    
        ## Get secret (read password) from connection handle
        try {
            $secret = Get-OCISecretsSecretBundle -SecretId $connection.UserPassword.SecretId -Stage Current -ErrorAction Stop
        }
        catch {
            throw "Get-OCISecretsSecretBundle: $_"
        }
    
        ## Create connection string
        $fullConnStr = $adb.ConnectionStrings.Low
        $connStr =  $fullConnStr.Substring($fullConnStr.LastIndexOf("/") + 1)

        ## determine if mongodbapi is requested and enabled
        if ($true -eq $AsMongoDbApi) {
            if (0 -eq ($adb.DbToolsDetails | Where-Object {$_.IsEnabled -eq 'True'} | Where-Object {$_.Name -eq 'MongodbApi'}).Count) {
                throw "MongodbApi is not enabled for this ADB"
            } else {
                $targetPort = 27017
            }
        } 
        else {
            $targetPort = 1521
        }

        ## Create return Object
        $adbConnection = [PSCustomObject]@{
            UserName = $connection.UserName
            PasswordBase64 = $secret.SecretBundleContent.Content
            TargetHost = $adb.PrivateEndpointip
            TargetPort = $targetPort
            ConnStr = $connStr
        }

        $adbConnection
 
    } catch {
        ## Pass exception on back
        throw "New-OpuAdbConnection: $_"
    } finally {
        ## To Maximize possible clean ups, continue on error 
        $ErrorActionPreference = "Continue"
    
        ## Done, restore settings
        $ErrorActionPreference = $userErrorActionPreference
    }
}
