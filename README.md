
# oci-posh-utils

This is a PowerShell utility suite intended to help you automate access to resources in OCI that sits inside of a secure virtual network
or VCN (Virtual Cloud Network) in OCI speak using the Bastion service.

Key functionality:
- PowerShell cmdlets to manage Bastion sessions.
- PowerShell scripts that wraps the cmdlets and illustrates how you can integrate into your workflow, be that interactive or as part of automation.

It is assumed that the user is familiar with SSH.

## Cmdlets to manage Bastion sessions

The OCI Bastion service provides three types of sessions, two of which are supported by this module:
- Port forwarding sessions
- Managed SSH sessions

These are described in the doc [here](https://docs.oracle.com/en-us/iaas/Content/Bastion/Concepts/bastionoverview.htm). 
I have borrowed the illustation below from the doc. 

![Image from official doc](doc/bastion-overview.png)

Thw two key cmdlets that allows you to create sessions are: 

### New-OpuPortForwardingSessionFull

```
.SYNOPSIS
Create a port forwarding sesssion with OCI Bastion service.
Generate SSH key pair to be used for session.
Create the actual port forwarding SSH process.

Return an object to the caller:
```

```Powershell
$bastionSessionDescription = [PSCustomObject]@{
    PSTypeName = 'OpuPortBastionSession.Object'
    BastionSession = $bastionSession
    SShProcess = $sshProcess
    LocalPort = $useThisPort
    TargetHost = $TargetHost
    TargetPort = $TargetPort
    SessionExpires = <SessionExpireTimeInLocalTime>
}
```

### New-OpuManagedSshSessionFull

```
.SYNOPSIS
Create a mamnaged SSH sesssion with OCI Bastion service.

Return an object to the caller:

The SshCmd attribute contains a formated SSH command string that can be used directly on the command line.
The KeyFile, JumpUser/JumpHost & TargetUser/TargetHost/TargetPort are intended for use with automation tools 
such as Ansible and PyInfra.   
```

```Powershell
$bastionSessionDescription = [PSCustomObject]@{
    PSTypeName     = 'OpuManagedBastionSession.Object'
    BastionSession = $bastionSession
    SShCmd         = <fully formated ssh command>
    KeyFile        = <key file generated for the session>
    JumpUser       = <jump user for the session>
    JumpHost       = <jump host for the session>
    TargetUser     = <target user for the session>
    TargetHost     = <target host for the session>
    TargetPort     = <target port for the session<
    SessionExpires = <SessionExpireTimeInLocalTime>
}
```

## Utility scripts

## Requirements 

### OCI

### Auth 

### Etc


>>>>>>>>>>>>>>>>>


## Various 

OCI powershell utils

Code structure inspired by 
https://www.psplaybook.com/2025/02/06/powershell-modules-best-practices/

The initial inspiration for this set of utils was the Detabase Development Tools of OCI. 
In one operation the "engine" performs teh following actions: 
- Pull connection information from vault (ip, user, pass)
- Create a bastion session
- Create a port forwarding session through the  

```shell
tofu output -json db_ocids | ConvertFrom-Json
>>
ocid1.instance.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherex
ocid1.instance.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherey
ocid1.instance.oc1.eu-frankfurt-1.longcrypticuuidstyletexthereandlongcrypticuuidstyletextherez
```

```shell
tofu output -json db_ips | ConvertFrom-Json
>>
10.0.1.77
10.0.1.80
10.0.1.210
```

Import the psd1 to get 
```shell
Import-Module ./oci-posh-utils.psd1 
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
Function        Get-OpuSecret                                      0.8        oci-posh-utils
Function        New-OpuManagedSshSessionFull                       0.8        oci-posh-utils
Function        New-OpuPortForwardingSessionFull                   0.8        oci-posh-utils
Function        New-OpuSshConfigFileFromBastionManagedSession      0.8        oci-posh-utils
Function        New-OpuSshKeyFromKeygen                            0.8        oci-posh-utils
Function        New-OpuSshKeyFromSecret                            0.8        oci-posh-utils
Function        Remove-OpuManagedSshsessionFull                    0.8        oci-posh-utils
Function        Remove-OpuPortForwardingSessionFull                0.8        oci-posh-utils
Function        Test-OpuIpAddr                                     0.8        oci-posh-utils
Function        Test-OpuMysqlshAvailable                           0.8        oci-posh-utils
Function        Test-OpuOcidString                                 0.8        oci-posh-utils
Function        Test-OpuPortForwardingSessionFull                  0.8        oci-posh-utils
Function        Test-OpuSshAvailable                               0.8        oci-posh-utils
```

## Tidbits 

Q: Why ips and not (dns)names? 
A: The Bastion servicse only allows for ip addresses.
