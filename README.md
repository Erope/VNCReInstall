# VNCReInstall
Use your network to reinstall the system online, With VNC support.  
Now only supports Debian 9/10 x32/x64.  
Also, UEFI boot devices are not currently supported.  
Tests are not run on the physical machine.  

# Risk Warning
This is still a project under development. Although it is currently in the main branch, please do not test it on any machine with data.

# Requirements
* An **empty** host
* 512M RAM(**unstable**) | 1G RAM
* Good network connectivity(github deb.debian.org)
* Independent IPV4 address
* Open Port 5900

# Usage
## Install Debian 10 v64 (please fill network info and password by yourself)
```shell
wget https://raw.githubusercontent.com/Erope/VNCReInstall/main/InstallNET_debian.sh
bash InstallNET_debian.sh --ip-addr --ip-gate --ip-mask -p 
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

# Contact us
* Telegram: https://t.me/ShineNet_Q

# Tested platforms
* Ucloud 1G/2G
* AWS 512M/1G/4G/8G
* Buyvm 512M/4G

Welcome to contact us to provide more data

# Possible problems
## Multiple disks
* First, the exact disk may not be automatically selected when partitioning disk for linux root. Please select by yourself through VNC
* Secondly, the correct disk may not be selected when generating the grub file. Please enter the shell through VNC and generate the grub file by yourself

## Cannot enter graphical installation mode or VNC cannot be connected
The problem is complicated, the currently known possibility:
* Low available memory (less than 1G). 512M can also be installed theoretically, but there is no strict test. 
* A Fatal error occurred during installation. You need to seek help from your service provider. This possibility is small, but it cannot be ignored.
* Failed to enter the installer. Maybe you need to confirm whether it is a UEFI device? If not please contact us.

# Thanks
* [MoeClub.org](https://github.com/MoeClub)
* [veip007](https://github.com/veip007)
* [TigerVNC](https://tigervnc.org/)

# Problem
If you think the script has a bug, please submit ISSUE, of course, PR is also very welcome
