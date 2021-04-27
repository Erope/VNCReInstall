# VNCReInstall
Use your network to reinstall the system online, With VNC support.
Now only supports Debian 9/10 x32/x64.
Also, UEFI boot devices are not currently supported.
Tests are not run on the physical machine.

# Risk Warning
This is still a project under development. Although it is currently in the main branch, please do not test it on any machine with data.

# Requirements
* An **empty** host
* 512M RAM
* Good network connectivity
* Independent IPV4 address
* Open Port 5900

# Usage
## Install Debian 10 v64 (please fill network info and password by yourself)
```shell
wget https://raw.githubusercontent.com/Erope/VNCReInstall/main/InstallNET_debian.sh
bash Install_debian.sh --ip-addr --ip-gate --ip-mask -p 
```

## Parameter Description
* --ip-addr: IP address
* --ip-gate: Network gateway
* --ip-mask: Subnet mask like 255.255.0.0
* -d|--debian: 9/10 
* -v|--ver: 32/64
* -p|--password: Your password, with num and letter
* other: Due to many script modifications, other parameters may or may not be useful

# VNC Support
We use TigerVNC as the VNC server of the Debian installer, working on port 5900, without a password.
During the installation process, you can connect to VNC to view the installation progress, solve installation problems, and avoid reinstallation failures.

# Thanks
* MoeClub.org
* veip007
* TigerVNC
