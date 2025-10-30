

Install
```
Install-Module -Name OCI.PSModules.Common
Install-Module -Name OCI.PSModules.Core
Install-Module -Name OCI.PSModules.Bastion
Install-Module -Name OCI.PSModules.Computeinstanceagent
Install-Module -Name OCI.PSModules.Database
Install-Module -Name OCI.PSModules.DatabaseTools
Install-Module -Name OCI.PSModules.Identity
Install-Module -Name OCI.PSModules.Mysql
Install-Module -Name OCI.PSModules.Objectstorage
Install-Module -Name OCI.PSModules.Secrets
Install-Module -Name OCI.PSModules.Vault
Install-Module -Name OCI.PSModules.Resourcemanager
```

Remove
```
Uninstall-Module -Name OCI.PSModules.Bastion
Uninstall-Module -Name OCI.PSModules.Computeinstanceagent
Uninstall-Module -Name OCI.PSModules.Database
Uninstall-Module -Name OCI.PSModules.DatabaseTools
Uninstall-Module -Name OCI.PSModules.Identity
Uninstall-Module -Name OCI.PSModules.Mysql
Uninstall-Module -Name OCI.PSModules.Objectstorage
Uninstall-Module -Name OCI.PSModules.Secrets
Uninstall-Module -Name OCI.PSModules.Vault
Uninstall-Module -Name OCI.PSModules.Resourcemanager
Uninstall-Module -Name OCI.PSModules.Core
Uninstall-Module -Name OCI.PSModules.Common
```

Validate it works: 
```
> oci-posh-utils  Get-OCIIdentityRegionsList

Key Name
--- ----
AMS eu-amsterdam-1
ARN eu-stockholm-1
AUH me-abudhabi-1
BOG sa-bogota-1
BOM ap-mumbai-1
CDG eu-paris-1
CWL uk-cardiff-1
DXB me-dubai-1
FRA eu-frankfurt-1
GRU sa-saopaulo-1
HSG ap-batam-1
HYD ap-hyderabad-1
IAD us-ashburn-1
ICN ap-seoul-1
JED me-jeddah-1
JNB af-johannesburg-1
KIX ap-osaka-1
LHR uk-london-1
LIN eu-milan-1
MAD eu-madrid-1
MEL ap-melbourne-1
MRS eu-marseille-1
MTY mx-monterrey-1
MTZ il-jerusalem-1
NRT ap-tokyo-1
ORD us-chicago-1
ORF eu-madrid-3
PHX us-phoenix-1
QRO mx-queretaro-1
RUH me-riyadh-1
SCL sa-santiago-1
SIN ap-singapore-1
SJC us-sanjose-1
SYD ap-sydney-1
VAP sa-valparaiso-1
VCP sa-vinhedo-1
XSP ap-singapore-2
YNY ap-chuncheon-1
YUL ca-montreal-1
YYZ ca-toronto-1
ZRH eu-zurich-1
```