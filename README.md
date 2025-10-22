
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

### Longer version 

Assign value to local variable for id of bastion in your network and for secret in vault holding SSH key:
```powershell
$bastion_ocid='xyz...'
$sshkey_ocid='xyz...'
```

Get Json output from Terraform for the compute nodes you want to reach. 
Convert and assign to string.
```powershell
❯ terraform output -json ip_addresses
["10.0.1.128","10.0.1.161","10.0.1.30"]

> $ip_address_list = '["10.0.1.128","10.0.1.161","10.0.1.30"]' | ConvertFrom-Json

❯ $ip_address_list
10.0.1.128
10.0.1.161
10.0.1.30
```

Get SSH key secret from Vault: 
```powershell
> $file_name=Get-OpuSecret -SecretId $sshkey_ocid -AsFile $true -AsPlainText $true

❯ $file_name
C:\Users\espenbr\AppData\Local\Temp\tmpoucdv2.tmp
```

Invoke cmdlet for bastion session creation using pipeline syntax  
```powershell
> $bastion_session_list = $ip_address_list | New-OpuPortForwardingSessionFull -BastionId $bastion_ocid -LocalPort 9003

Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.128:22
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting for creation of SSH tunnel to complete
Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.161:22
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting for creation of SSH tunnel to complete
Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.30:22
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting for creation of SSH tunnel to complete
```

Verify contents of session list
```powershell
❯ $bastion_session_list

BastionSession : Oci.BastionService.Models.Session
SShProcess     : System.Diagnostics.Process (Idle)
LocalPort      : 9003
Target         : 10.0.1.128:22
SessionExpires : 20.10.2025 18:22:25

BastionSession : Oci.BastionService.Models.Session
SShProcess     : System.Diagnostics.Process (Idle)
LocalPort      : 9004
Target         : 10.0.1.161:22
SessionExpires : 20.10.2025 18:23:07

BastionSession : Oci.BastionService.Models.Session
SShProcess     : System.Diagnostics.Process (Idle)
LocalPort      : 9005
Target         : 10.0.1.30:22
SessionExpires : 20.10.2025 18:23:49
```

Now, connect to local ports to validate.
In this case we use fab command line tool from Fabric, the Python tool. 

```powershell
fab --hosts opc@127.0.0.1:9003,opc@127.0.0.1:9004,opc@127.0.0.1:9005 -i $file_name -- 'hostname'
db2
db1
db3
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

