
<#
.SYNOPSIS
Create a ssh config file from bastion session description object(s) to enable 
remote configuration management through ssh based tools such as Ansibel and PyInfra.

Configuartion is saved in a temporary file,the name of the temporary file is returned to the caller. 

.DESCRIPTION


Temporary file content will look like so:

Host <HOST-BASE-NAME>1
  HostName <TARGET-IP-INSIDE-VCN>
  User <USERNAME-GIVEN-WHEN-SESSION-CREATED>
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  ProxyCommand ssh -i /tmp/bastionkey-2025_11_07_11_25_41-9087 -W %h:%p -p 22 ocid1.bastionsession.oc1.eu-frankfurt-1.<OCI-UUID>@host.bastion.<OCI-REGION>.oci.oraclecloud.com

The validity of the output can be verified by execyting "ssh -F <tempfile> <target> -i <target-keyfile>".

.PARAMETER BastionSessionDescription

$BastionSessionDescription = [PSCustomObject]@{
    PSTypeName     = 'OpuManagedBastionSession.Object'
    BastionSession = $bastionSession
    SShArgs        = <fully formated ssh command>
    KeyFile        = <key file generated for the session>
    JumpUser       = <jump user for the session>
    JumpHost       = <jump host for the session>
    TargetUser     = <target user for the session>
    TargetHost     = <target host for the session>
    TargetPort     = <target port for the session<
    SessionExpires = <SessionExpireTimeInLocalTime>
}
 
.PARAMETER HostBaseName
Base name to use when defining host(s) in config. 
If value is "db" and $AppendSerial is $true, the hosts will be called db1 .. dbN.
If value is "db" and $AppendSerial is $false, the hosts will be called db. 
Should only be used if only one host, this is teh caller's responsibility.

.PARAMETER AppendSerial
Defines if a serial number (starting with 1) should be appended to $HostBaseName.
Default $true.

.PARAMETER TargetKeyFile
Ssh key file to be used for accessing target host. 

.PARAMETER IsProd
Determines if "unsafe" defaults are added to config for each target host.
Default $false.

When $false:
    StrictHostKeyChecking no 
    UserKnownHostsFile=/dev/null 
#>

function New-OpuSshConfigFileFromBastionManagedSession {
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'Full Bastion Port Forwarding Session Description Object')]
        [PSTypeName('OpuManagedSshSessionFull.Object')]$BastionSessionDescription, 
        [Parameter(HelpMessage = 'Is this a production config ($false)')]
        [bool]$IsProd = $false
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop" 
        ## END: generic section

        ## "Iterator" for assigning host names
        $globalCount = 0

        Write-Verbose "New-OpuSshConfigFileFromBastionManagedSession: begin"

        $tempFile = New-TemporaryFile
    }

    process {
        
        $globalCount++

        $_targetHost = $BastionSessionDescription.Targethost
        $_targetPort = $BastionSessionDescription.TargetPort
        $_targetUser = $BastioNSessionDescription.TargetUser
        $_keyFile    = $BastioNSessionDescription.KeyFile

        $_jumpUser   = $BastioNSessionDescription.JumpUser
        $_jumpHost   = $BastioNSessionDescription.JumpHost


        Out-File -Append -FilePath $tempFile -InputObject "#" 

        Out-File -Append -FilePath $tempFile -InputObject "Host ${_targetHost}"

        Out-File -Append -FilePath $tempFile -InputObject "  User ${_targetUser}"
        Out-File -Append -FilePath $tempFile -InputObject "  Port ${_targetPort}"
        Out-File -Append -FilePath $tempFile -InputObject "  ServerAliveInterval 30"
        Out-File -Append -FilePath $tempFile -InputObject "  ServerAliveCountMax 4"

        if ($false -eq $IsProd) {
            Out-File -Append -FilePath $tempFile -InputObject "  StrictHostKeyChecking no"
            if ($false -eq $IsWindows) {
                Out-File -Append -FilePath $tempFile -InputObject "  UserKnownHostsFile=/dev/null"
            }
            else {
                Out-File -Append -FilePath $tempFile -InputObject "  UserKnowHostFile=\\.\NUL"
            }
        }

        Out-File -Append -FilePath $tempFile -InputObject "  ProxyCommand ssh -i ${_keyFile} -W %h:%p -p 22 ${_jumpUser}@${_jumpHost}"
    }
   
    end {
        Write-Verbose "New-OpuSshConfigFileFromBastionManagedSession: end"

        ## Done, restore settings
        $ErrorActionPreference = $globalUserErrorActionPreference

        $tempFile.FullName
    }    
}
