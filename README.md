
# oci-posh-utils

OCI powershell utils


Code structure inspired by 
https://www.psplaybook.com/2025/02/06/powershell-modules-best-practices/


## User guide sample 

Assign value to local variable for id of bastion in your network
```powershell
$bastion_ocid='xyz...'
```

Get Json output from Terraform for the compute nodes you want to reach. 
```powershell
❯ terraform output -json ip_addresses
["10.0.1.60","10.0.1.253","10.0.1.160"]
```

Convert and assign to string
```powershell
❯ $ip_address_list = '["10.0.1.60","10.0.1.253","10.0.1.160"]' | ConvertFrom-Json

❯ $ip_address_list
10.0.1.60
10.0.1.253
10.0.1.160
```

Invoke cmdlet for bastion session creation using pipeline syntax  
```
> $bastion_session_list = $ip_address_list | New-OpuPortForwardingSessionFull -BastionId $bastion_ocid

Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.60:22
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting for creation of SSH tunnel to complete
Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.253:22
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting for creation of SSH tunnel to complete
Creating ephemeral key pair
Creating Port Forwarding Session to 10.0.1.160:22
Waiting for creation of bastion session to complete
Creating SSH tunnel
Waiting for creation of SSH tunnel to complete
```

Verify contents of session list
```powershell
❯ $bastion_session_list

BastionSession : Oci.BastionService.Models.Session
SShProcess     : System.Diagnostics.Process (Idle)
LocalPort      : 9062
Target         : 10.0.1.60:22
SessionExpires : 17.10.2025 17:55:05

BastionSession : Oci.BastionService.Models.Session
SShProcess     : System.Diagnostics.Process (Idle)
LocalPort      : 9069
Target         : 10.0.1.253:22
SessionExpires : 17.10.2025 17:55:47

BastionSession : Oci.BastionService.Models.Session
SShProcess     : System.Diagnostics.Process (Idle)
LocalPort      : 9001
Target         : 10.0.1.160:22
SessionExpires : 17.10.2025 17:56:28
```

Now, connect to local ports to validate.
In this case we use fab command line tool from Fabric, the Python tool. 

```powershell
fab --hosts opc@127.0.0.1:9069,opc@127.0.0.1:9062,opc@127.0.0.1:9001 -i <somefilenamehere> -- 'hostname'
db2
db1
db3
```

## Remember

```powershell
Get-Command -Module oci-posh-utils

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Test-OpuMysqlshAvailable                           0.0        oci-posh-utils
Function        Test-OpuSqlclAvailable                             0.0        oci-posh-utils
Function        Test-OpuSshAvailable                               0.0        oci-posh-utils
```

