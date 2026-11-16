

# oci-posh-utils

This is a PowerShell utility suite intended to help you automate access to resources in OCI (Oracle Cloud Infrastructure) 
that sits inside of a secure virtual network or VCN (Virtual Cloud Network) in OCI speak using the Bastion service.

It is assumed that the user is familiar with SSH.

```
                        +-----------------------------+
                        |        Public Internet      |
                        +-----------------------------+
                                      |
                                      | SSH / Managed Session
                                      v
                        +-----------------------------+
                        |       OCI Bastion Service   |
                        |  - No public IP needed      |
                        |  - Time-bound access        |
                        |  - SSH / RDP / Port Fwd     |
                        +-----------------------------+
                                      |
                                      | Private Access Tunnel
                                      v
       -------------------------------------------------------------------------------------
       |                    OCI Virtual Cloud Network (VCN)                                |
       |                                                                                   |
       |   Left: SSH/RDP to Private Compute            Right: Port Fwd to DB               |
       |                                                                                   |
       |   +-------------------+                         +-------------------+             |
       |   | Private Subnet    |                         | Private Subnet    |             |
       |   | (No Public IPs)   |                         | (No Public IPs)   |             |
       |   +-------------------+                         +-------------------+             |
       |            |                                            |                         |
       |            | SSH / RDP via Bastion                      | Port Forwarding Session |
       |            v                                            v                         |
       |   +-------------------+                         +----------------------------+    |
       |   | Compute Instance  |                         | Database System / DB Node  |    |
       |   | (Target Host)     |                         | (e.g., ATP, DB System)     |    | 
       |   +-------------------+                         +----------------------------+    |
       |                                                                                   |
       ------------------------------------------------------------------------------------|

Notes:
- Left side: Standard Bastion-managed SSH or RDP session to compute resources.
- Right side: Bastion port-forwarding session to database targets (e.g., Oracle DB System, Autonomous Database private endpoint).
- No public IPs required for either compute or database hosts.
- Sessions are ephemeral, policy-controlled, and logged.
```

## Use cases 

1. Set up (virtual) wiring to make hosts -- with private addresses no permanent path to the public -- inside a VCN accessible to 
ssh based configuration management tools such as Ansible and PyInfra.
2. Configure local ports to point to endpoints inside a VCN -- with private addresses no permanent path to the public -- to 
be used with database tools such as Liquibase and Flyway. 
3. Create an interactive session to a serviec endpoint inside of a VCN -- with private addresses no permanent path to the public -- to 
be used with tools like `ssh` and and other cli like tools.

Item (3) above was how this project started. I was so impressed by the ability to launch `sqlcl` or `mysqlsh` inside of the OCI control
panel that I wanted to replicate it. `./Scripts/Invoke_Ssh_Session.ps1` can be used as
templates for creating your own scripts and for tips on how you can possibly automate access to database endpoints inside of OCI.   

(i) There useed to be a `./Scripts/Invoke_Mongosh_Session.ps1` as well. Thsi shwos teh use of port forwarding for a DB tool. 
The script itself It has been parked in the brach called `classic`. 

(ii) There also used to be an explanatin and corresponding source for a containerizing. This is also parked in the `classic` branch. 

## Notes 

## Missing or TODO

- Cmdlets named `Test-...` do not follow Powershell best practice of returning `$true` or `$false`.  Rather they throw errors. I did this on purpose because I always use them within `try/catch` blocks. 

### Requirements for regular setup

Clone the repo. 

The following software must be installed in your environment:
- [OCI PowerShell Modules](doc/powershell_modules.md) 
- OpenSSH binaries

Import the cmdlets like so: ` Import-Module ./oci-posh-utils.psd1`. 

### Why PowerShell? 

PowerShell is an extremely powerful and forgiving environment for exploring an API. I especially appreciate the ability to inspect returned objects. 
This is the ultimate learning environment for me.


### Inspiration

OCI powershell utils

Code structure inspired by 
https://www.psplaybook.com/2025/02/06/powershell-modules-best-practices/

The initial inspiration for this set of utils was the Database Development Tools of OCI. 
In one operation the "engine" performs teh following actions: 
- Pull connection information from vault (ip, user, pass)
- Create a bastion session
- Create a port forwarding session through the  

### Check status after loading module

```pwsh
Get-Command -Module oci-posh-utils

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Get-OpuSecret                                      0.9        oci-posh-utils
Function        Import-OpuObject                                   0.9        oci-posh-utils
Function        Invoke-OpuSshSession                               0.9        oci-posh-utils
Function        New-OpuAdbConnection                               0.9        oci-posh-utils
Function        New-OpuDynPortForwardingSession                    0.9        oci-posh-utils
Function        New-OpuManagedSshSessionFull                       0.9        oci-posh-utils
Function        New-OpuOciConfigFileFromEnv                        0.9        oci-posh-utils
Function        New-OpuPortForwardingSession                       0.9        oci-posh-utils
Function        New-OpuPortForwardingSessionFull                   0.9        oci-posh-utils
Function        New-OpuSshConfigFileFromBastionManagedSession      0.9        oci-posh-utils
Function        New-OpuSshKeyFromKeygen                            0.9        oci-posh-utils
Function        New-OpuSshKeyFromSecret                            0.9        oci-posh-utils
Function        Read-OpuTofuVariables                              0.9        oci-posh-utils
Function        Remove-OpuDynPortForwardingSession                 0.9        oci-posh-utils
Function        Remove-OpuManagedSshsessionFull                    0.9        oci-posh-utils
Function        Remove-OpuPortForwardingSession                    0.9        oci-posh-utils
Function        Remove-OpuPortForwardingSessionFull                0.9        oci-posh-utils
Function        Save-OpuObject                                     0.9        oci-posh-utils
Function        Test-OpuIpAddr                                     0.9        oci-posh-utils
Function        Test-OpuMongoshAvailable                           0.9        oci-posh-utils
Function        Test-OpuMysqlshAvailable                           0.9        oci-posh-utils
Function        Test-OpuOcidString                                 0.9        oci-posh-utils
Function        Test-OpuOpensslAvailable                           0.9        oci-posh-utils
Function        Test-OpuSshAvailable                               0.9        oci-posh-utils
Function        Test-OpuVariablesLoaded                            0.9        oci-posh-utils

```
