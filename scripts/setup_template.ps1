
<#
Set

$db_ocids
$bastion_ocid 


Decide where pipe output 
#>

$key_file = "/Users/espenbr/GitHub/oci-posh-utils/config/db.key"
$cfg_file = "/Users/espenbr/GitHub/oci-posh-utils/config/temp_ssh_config"

$bastion_sessions_managed = $db_ocids | OpuManagedSshSessionFull -BastionId $bastion_ocid

$temp_file = $bastion_sessions_managed | New-OpuSshConfigFileFromBastionManagedSession -IsProd $false -HostBaseName db -TargetKeyFile $key_file 

cat $temp_file > $cfg_file

