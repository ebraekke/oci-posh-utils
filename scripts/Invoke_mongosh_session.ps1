## TODO: Finish up documentation before publishing 

<#
.SYNOPSIS
Invoke  an mongosh sesssion with a target host accessible through the OCI Bastion service using a DatabaseToolsConnection.

.DESCRIPTION
Using the Bastion service and tunneling, a mongosh session will be invoked on the target DB system identified by -ConnectionId.
The referenced DatabaseTools object contains all the information needed to establish a connection: 
- username
- portt
- ip address
- connection string

The port forwarding session is created by the New-OpuPortForwardingSessionFull cmdlet. 
This allows you to "connect" through the Bastion service via a local port and to your destination: $TargetHost:$TargetPort   

A path from the Bastion to the target is required.
The Bastion session inherits TTL from the Bastion (instance). 

.PARAMETER BastionId
OCID of Bastion with wich to create a session. 
 
.PARAMETER ConnectionId
OCID of connection containing the details about the database system. 

.PARAMETER CmdAsVerbose
Set to $true get verbose output from mongosh. 
$false is default.

.EXAMPLE 
## Successfully invoking script and connecting to DB via bastion
> ./Scripts/Invoke_mongosh_session.ps1 -BastionId $bastion_ocid -ConnectionId $conn_ocid
Getting details from connection
Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.95:27017
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting for creation of SSH tunnel to complete
Launching mongosh
Current Mongosh Log ID:	6929a2d79888f1869f5aa2d4
Connecting to:		mongodb://<credentials>@localhost:9095/admin?authMechanism=PLAIN&authSource=%24external&ssl=true&retryWrites=false&loadBalanced=true&serverSelectionTimeoutMS=2000&tls=true&tlsAllowInvalidCertificates=true&appName=mongosh+2.5.9
Using MongoDB:		7.0.22
Using Mongosh:		2.5.9

For mongosh info see: https://www.mongodb.com/docs/mongodb-shell/

admin> 

.EXAMPLE 
## Invoking script without setting path to mongosh
> ./Scripts/Invoke_mongosh_session.ps1 -BastionId $bastion_ocid -ConnectionId $conn_ocid
Write-Error: Invoke_Mongosh_Session.ps1: Test-Executable: mongosh not found

.EXAMPLE 
## Invoking script with a connection that has been deleted 
>./Scripts/Invoke_mongosh_session.ps1 -BastionId $bastion_ocid -ConnectionId $conn_ocid
Getting details from connection
Write-Error: Invoke_Mongosh_Session.ps1: New-OpuAdbConnection: Get-OCIDatabasetoolsconnection: One or more errors occurred. (Failed to reach desired state.)

.EXAMPLE 
## Invoking script without activating MongodbApi first
>./Scripts/Invoke_mongosh_session.ps1 -BastionId $bastion_ocid -ConnectionId $conn_ocid
Getting details from connection
Write-Error: Invoke_Mongosh_Session.ps1: New-OpuAdbConnection: MongodbApi is not enabled for this ADB

#>

param(
    [Parameter(Mandatory, HelpMessage='OCID of Bastion')]
    [String]$BastionId, 
    [Parameter(Mandatory, HelpMessage='OCID of connection')]
    [String]$ConnectionId,
    [Parameter(HelpMessage='Run mongosh in verbose mode')]
    [bool]$CmdAsVerbose=$false
)

Write-Verbose "Invoke_Mongosh_Session.ps1: PSScriptRoot = ${PSScriptRoot}"

Write-Verbose "Params: begin"
Write-Verbose $BastionId
Write-Verbose $ConnectionId
Write-Verbose "Params: end"

try {
    ## START: generic section
    $UserErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop" 

    Import-Module "${PSScriptRoot}/../oci-posh-utils.psd1"
    ## END: generic section

    ## Ensure params are ok
    Test-OpuOcidString -OcidString $BastionId -IsOfType "bastion"
    Test-OpuOcidString -OcidString $ConnectionId -IsOfType "databasetoolsconnection"
      
    ## Make sure mongosh is within reach first
    Test-OpuMongoshAvailable

    ## Grab connection
    $adbConnectionDescription = New-OpuAdbConnection -ConnectionId $ConnectionId -AsMongodbApi $true

    ## Assign to local variables for readability, port magic handled in cmdlet
    $userName = $adbConnectionDescription.UserName
    $passwordBase64 = $adbConnectionDescription.PasswordBase64
    $targetHost = $adbConnectionDescription.TargetHost
    $targetPort = $adbConnectionDescription.TargetPort
    
    ## Create session and process, ask for dyn local port, get information in custom object -- used in teardown below
    $bastionSessionDescription = New-OpuPortForwardingSessionFull -BastionId $BastionId -TargetHost $TargetHost -TargetPort $TargetPort -LocalPort 0
    $localPort = $bastionSessionDescription.LocalPort
  
    $password = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($passwordBase64))
    $urlEncodedPassword = [System.Web.HttpUtility]::UrlEncode($password)

    ## Stitch together a connection url for mongosh
    ## Use localhost, 127.0.0.1 will result in "MongoNetworkError: Client network socket disconnected before secure TLS connection was established"
    $hostUrl = "mongodb://${userName}:${urlEncodedPassword}@localhost:${localPort}/${userName}"
    $paraUrl = '?authMechanism=PLAIN&authSource=$external&ssl=true&retryWrites=false&loadBalanced=true'

    $connUrl = "${hostUrl}${paraUrl}"
    Write-Host "Launching mongosh"
 
    if ($true -eq $CmdAsVerbose) {
        mongosh --verbose --tls --tlsAllowInvalidCertificates "${connUrl}"
    }
    else {
        mongosh --tls --tlsAllowInvalidCertificates "${connUrl}"
    }
}
catch {
    ## What else can we do?
    Write-Error "Invoke_Mongosh_Session.ps1: $_"
    return $false
}
finally {
    ## START: generic section
    ## To Maximize possible clean ups, continue on error 
    $ErrorActionPreference = "Continue"
    
    ## Request cleanup if session object has been created
    if ($null -ne $bastionSessionDescription) {
        Remove-OpuPortForwardingSessionFull -BastionSessionDescription $bastionSessionDescription
    }

    ## Done, restore settings
    $ErrorActionPreference = $userErrorActionPreference
    ## END: generic section
}