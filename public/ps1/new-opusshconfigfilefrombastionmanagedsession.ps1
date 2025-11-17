
<#
.SYNOPSIS
x

.DESCRIPTION
Output:

Host <HOST-BASE-NAME>1
  HostName <TARGET-IP-INSIDE-VCN>
  User <USERNAME-GIVEN-WHEN-SESSION-CREATED>
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  IdentityFile <FULL-NAME-OF-INPUT-KEY-HERE>
  UserKnownHostsFile /dev/null
  ProxyCommand ssh -i /tmp/bastionkey-2025_11_07_11_25_41-9087 -W %h:%p -p 22 ocid1.bastionsession.oc1.eu-frankfurt-1.<OCI-UUID>@host.bastion.<OCI-REGION>.oci.oraclecloud.com

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

 
#>

function New-OpuSshConfigFileFromBastionManagedSession {
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = 'Full Bastion Port Forwarding Session Description Object')]
        [PSTypeName('OpuManagedBastionSession.Object')]$BastionSessionDescription, 
        [Parameter(Mandatory, HelpMessage = 'Base name to use when defining Host in config')]
        [String]$HostBaseName,
        [Parameter(HelpMessage = 'Append serial number (1..n) to $HostBaseName')]
        [bool]$AppendSerial = $true,
        [Parameter(Mandatory, HelpMessage = 'Name of keyfile to add to target for the $OsUser')]
        [String]$TargetKeyFile,
        [Parameter(HelpMessage = 'Is this a production config ($false)')]
        [bool]$IsProd = $false
    )

    begin {
        ## START: generic section 
        $globalUserErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue" 
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
        Out-File -Append -FilePath $tempFile -InputObject "# ${HostBaseName} number ${globalCount} - target ${_targetHost}"

        if ($false -eq $AppendSerial) {
            Out-File -Append -FilePath $tempFile -InputObject "Host ${HostBaseName}"
        } else {
            Out-File -Append -FilePath $tempFile -InputObject "Host ${HostBaseName}${globalCount}"
        }

        Out-File -Append -FilePath $tempFile -InputObject "  Hostname ${_targetHost}"
        Out-File -Append -FilePath $tempFile -InputObject "  User ${_targetUser}"
        Out-File -Append -FilePath $tempFile -InputObject "  Port ${_targetPort}"
        Out-File -Append -FilePath $tempFile -InputObject "  IdentityFile ${TargetKeyFile}"
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
