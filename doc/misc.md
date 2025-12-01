# Containerfile in progress 


wget -P /tmp https://cdn.mysql.com//Downloads/MySQL-Shell/mysql-shell-8.4.7-linux-glibc2.28-arm-64bit.tar.gz

cd /home/app

tar -zxvf /tmp/mysql-shell-8.4.7-linux-glibc2.28-arm-64bit.tar.gz

chown -R app:app mysql-shell-8.4.7-linux-glibc2.28-arm-64bit


/home/app/mysql-shell-8.4.7-linux-glibc2.28-arm-64bit/bin> ./mysqlsh --version
Cannot set LC_ALL to locale en_US.UTF-8: No such file or directory
/home/app/mysql-shell-8.4.7-linux-glibc2.28-arm-64bit/bin/mysqlsh   Ver 8.4.7 for Linux on aarch64 - for MySQL 8.4.7 (MySQL Community Server (GPL))

??
apt-get install -y locales

# Podman start

https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-in-docker?view=powershell-7.5


## Building
```
# cd top level in project
podman build --tag poshtest -f ./container/Containerfile .h
```

## Testing 

Userid of app is 1654
Maps .oci config directory with only relative references to  key files
```
podman run -u 1654 -it -v ~/.oci:/home/app/.oci:ro poshtest
```

Inside (as app):
```
Get-OCIIdentityRegionsList
...
```

# This is Debian 

````
PS /> cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
VERSION_CODENAME=bookworm
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```
TODO: 
https://www.mongodb.com/docs/mongodb-shell/install/?operating-system=linux&linux-distribution=debian&debian-version=debian12

# Archive 

>>>
Start a container
```
podman pull mcr.microsoft.com/dotnet/sdk:8.0

podman run -it mcr.microsoft.com/dotnet/sdk:8.0 pwsh
```

Inside:
```
#
>id
uid=0(root) gid=0(root) groups=0(root)

apt-update

... 

All packages are up to date.

#
apt install openssh-client -y

#
>su - app 
>id
uid=1654(app) gid=1654(app) groups=1654(app)

```
start again with user app
```
#
podman run -u 1654 -it mcr.microsoft.com/dotnet/sdk:8.0 pwsh
PowerShell 7.4.12

#
>id
uid=1654(app) gid=1654(app) groups=1654(app)
```

## start again with root, install and verify
```
#
podman run  -it mcr.microsoft.com/dotnet/sdk:8.0 pwsh  

... 

apt update

... 

All packages are up to date.

#
apt install openssh-client -y


su --shell /usr/bin/pwsh app 

cd ${HOME}

# 
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

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


mkdir ${HOME}/.ssh

touch ${HOME}/.ssh/known_hosts
chmod 0600 ${HOME}/.ssh/known_hosts

$REGION="eu-frankfurt-1"

ssh-keyscan -H host.bastion.${REGION}.oci.oraclecloud.com >> ${HOME}/.ssh/known_hosts

git clone https://github.com/ebraekke/oci-posh-utils.git

```

## Config

```
podman machine init 

#
>cat /Users/espenbr/.config/containers/containers.conf
[machine]
provider="applehv"

#
>podman machine init 
Looking up Podman Machine image at quay.io/podman/machine-os:5.7 to create VM
Getting image source signatures
Copying blob bb1db03b631a done   | 
Copying config 44136fa355 done   | 
Writing manifest to image destination
bb1db03b631ad8c2d754206c03d1c0b016a36d47e5d8b1ebcfff4421adc79443
Extracting compressed file: podman-machine-default-arm64.raw: done  
Machine init complete
To start your machine run:

	podman machine start

#
>podman machine start 
Starting machine "podman-machine-default"

This machine is currently configured in rootless mode. If your containers
require root permissions (e.g. ports < 1024), or if you run into compatibility
issues with non-podman clients, you can switch using the following command:

	podman machine set --rootful

API forwarding listening on: /var/run/docker.sock
Docker API clients default to this address. You do not need to set DOCKER_HOST.

Machine "podman-machine-default" started successfully

#
>podman run hello-world
Trying to pull quay.io/podman/hello:latest...
Getting image source signatures
Copying blob sha256:1ff9adeff4443b503b304e7aa4c37bb90762947125f4a522b370162a7492ff47
Copying config sha256:83fc7ce1224f5ed3885f6aaec0bb001c0bbb2a308e3250d7408804a720c72a32
Writing manifest to image destination
!... Hello Podman World ...!

         .--"--.           
       / -     - \         
      / (O)   (O) \        
   ~~~| -=(,Y,)=- |         
    .---. /`  \   |~~      
 ~/  o  o \~~~~.----. ~~   
  | =(X)= |~  / (O (O) \   
   ~~~~~~~  ~| =(Y_)=-  |   
  ~~~~    ~~~|   U      |~~ 

Project:   https://github.com/containers/podman
Website:   https://podman.io
Desktop:   https://podman-desktop.io
Documents: https://docs.podman.io
YouTube:   https://youtube.com/@Podman
X/Twitter: @Podman_io
Mastodon:  @Podman_io@fosstodon.org

```
