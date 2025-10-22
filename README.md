
# oci-posh-utils

OCI powershell utils


Code structure inspired by 
https://www.psplaybook.com/2025/02/06/powershell-modules-best-practices/


Import the psd1 to get 
```

```
## User guide sample 

### Super short

1. Assign local variables for secrets and bastion. Download SSH key from vault. 
2. Get IP addresses from terraform into local list.
3. Create SSH forwarding sessions for each target, starting at 9003.
4. Execute configuration command against all targets.

```powershell
## 1.
$bastion_ocid='xyz...'
$sshkey_ocid='xyz...'
$file_name=Get-OpuSecret -SecretId $sshkey_ocid -AsFile $true -AsPlainText $true

## 2.
$ip_address_list = terraform output -json ip_addresses | ConvertFrom-Json

## 3.  
$bastion_session_list = $ip_address_list | New-OpuPortForwardingSessionFull -BastionId $bastion_ocid -LocalPort 9003

## 4.  
foreach ($target in $bastion_session_list) {
    $localPort =$target.LocalPort 
    fab --hosts opc@127.0.0.1:${localPort} -i $file_name -- 'hostname'
}
db1
db2
db3
```

Configure firewalls for MySQL
```powershell
foreach ($target in $bastion_session_list) {
    $localPort =$target.LocalPort 
    fab --hosts opc@127.0.0.1:${localPort} -i $file_name configureFirewalld
}
```


Install and configure MySQL
```powershell
$mysql_password = Get-OpuSecret -SecretId $mysql_secret_ocid -AsPlainText $true -AsFile $false

foreach ($target in $bastion_session_list) {
    $localPort =$target.LocalPort 
    fab --hosts opc@127.0.0.1:${localPort} -i $file_name runMysqlInstaller --newpassword=${mysql_password}
}
```

or just one, I know it is on 9003, but address into list.
```powershell
$localPort =$bastion_session_list[0].LocalPort 
fab --hosts opc@127.0.0.1:${localPort} -i $file_name runMysqlInstaller --newpassword=${mysql_password}
```

Then finally, apply config changes
```powershell
$localPort =$bastion_session_list[0].LocalPort 
fab --hosts opc@127.0.0.1:${localPort} -i $file_name configureMysqlSettings --password=${mysql_password}
```


## Remember

```powershell
❯ Get-Command -Module oci-posh-utils

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Get-OpuSecret                                      0.9        oci-posh-utils
Function        New-OpuPortForwardingSessionFull                   0.9        oci-posh-utils
Function        New-OpuSshKeyFromKeygen                            0.9        oci-posh-utils
Function        New-OpuSshKeyFromSecret                            0.9        oci-posh-utils
Function        Remove-OpuPortForwardingSessionFull                0.9        oci-posh-utils
Function        Test-OpuMongoshAvailable                           0.9        oci-posh-utils
Function        Test-OpuMysqlshAvailable                           0.9        oci-posh-utils
Function        Test-OpuPipeLine                                   0.9        oci-posh-utils
Function        Test-OpuPortForwardingSessionFull                  0.9        oci-posh-utils
Function        Test-OpuSqlclAvailable                             0.9        oci-posh-utils
Function        Test-OpuSshAvailable                               0.9        oci-posh-utils
```

