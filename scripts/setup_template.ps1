
<#
Set

$db_ips
$bastion_ocid 

$key_file = "/Users/espenbr/GitHub/oci-posh-utils/config/db.key"

Decide where pipe output 
#>

$cfgFile = "/Users/espenbr/GitHub/oci-posh-utils/config/temp_ssh_config"

$bastion_session_list = $db_ips | New-OpuPortForwardingSessionFull -BastionId $bastion_ocid -LocalPort 9001

$bastion_session_list | New-OpuSshConfigFileFromBastionSession -HostBaseName db -TargetKeyFile $key_file > $cfgFile
