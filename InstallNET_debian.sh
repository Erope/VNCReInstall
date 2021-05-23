#!/bin/bash

## License: GPL
## It can reinstall Debian online, with VNC support.
## Original Author: MoeClub.org veip007
## Now Author: Erope
## Blog: https://www.shinenet.cn

export tmpVER=''
export tmpDIST=''
export tmpURL=''
export tmpWORD=''
export tmpMirror=''
export tmpSSL=''
export tmpINS=''
export ipAddr=''
export ipMask=''
export ipGate=''
export Relese=''
export ddMode='0'
export setNet='0'
export setRDP='0'
export setIPv6='0'
export isMirror='0'
export FindDists='0'
export loaderMode='0'
export IncFirmware='0'
export SpikCheckDIST='0'
export setInterfaceName='0'
export UNKNOWHW='0'
export UNVER='6.4'

down_url='https://raw.githubusercontent.com/Erope/VNCReInstall/main'
MEMLIMIT=460

# 默认参数设置
while [[ $# -ge 1 ]]; do
  case $1 in
    -v|--ver)
      shift
      tmpVER="$1"
      shift
      ;;
    -d|--debian)
      shift
      Relese='Debian'
      tmpDIST="$1"
      shift
      ;;
    -u|--ubuntu)
      shift
      Relese='Ubuntu'
      tmpDIST="$1"
      shift
      ;;
    -c|--centos)
      shift
      Relese='CentOS'
      tmpDIST="$1"
      shift
      ;;
    -dd|--image)
      shift
      ddMode='1'
      tmpURL="$1"
      shift
      ;;
    -p|--password)
      shift
      tmpWORD="$1"
      shift
      ;;
    -i|--interface)
      shift
      interface="$1"
      shift
      ;;
    --ip-addr)
      shift
      ipAddr="$1"
      shift
      ;;
    --ip-mask)
      shift
      ipMask="$1"
      shift
      ;;
    --ip-gate)
      shift
      ipGate="$1"
      shift
      ;;
    --dev-net)
      shift
      setInterfaceName='1'
      ;;
    --loader)
      shift
      loaderMode='1'
      ;;
    --prefer)
      shift
      tmpPrefer="$1"
      shift
      ;;
    -apt|-yum|--mirror)
      shift
      isMirror='1'
      tmpMirror="$1"
      shift
      ;;
    -rdp)
      shift
      setRDP='1'
      WinRemote="$1"
      shift
      ;;
    -ssl)
      shift
      tmpSSL="$1"
      shift
      ;;
    -firmware)
      shift
      IncFirmware="1"
      ;;
    --ipv6)
      shift
      setIPv6='1'
      ;;
    *)
      if [[ "$1" != 'error' ]]; then echo -ne "\nInvaild option: '$1'\n\n"; fi
      echo -ne " Usage:\n\tbash $(basename $0)\t-d/--debian [\033[33m\033[04mdists-name\033[0m]\n\t\t\t\t-u/--ubuntu [\033[04mdists-name\033[0m]\n\t\t\t\t-c/--centos [\033[33m\033[04mdists-verison\033[0m]\n\t\t\t\t-v/--ver [32/\033[33m\033[04mi386\033[0m|64/amd64]\n\t\t\t\t--ip-addr/--ip-gate/--ip-mask\n\t\t\t\t-apt/-yum/--mirror\n\t\t\t\t-dd/--image\n\t\t\t\t-a/--auto\n\t\t\t\t-m/--manual\n"
      exit 1;
      ;;
    esac
  done

[[ "$EUID" -ne '0' ]] && echo "Error:This script must be run as root!" && exit 1;

# 检查依赖
function CheckDependence(){
FullDependence='0';
for BIN_DEP in `echo "$1" |sed 's/,/\n/g'`
  do
    if [[ -n "$BIN_DEP" ]]; then
      Founded='0';
      for BIN_PATH in `echo "$PATH" |sed 's/:/\n/g'`
        do
          ls $BIN_PATH/$BIN_DEP >/dev/null 2>&1;
          if [ $? == '0' ]; then
            Founded='1';
            break;
          fi
        done
      if [ "$Founded" == '1' ]; then
        echo -en "ok\t";
      else
        FullDependence='1';
        echo -en "Not Install\t";
      fi
      echo -en "\t$BIN_DEP\n";
    fi
  done
if [ "$FullDependence" == '1' ]; then
  echo -ne "\nError! Please use 'apt-get' or 'yum' install it.\n\n\n"
  exit 1;
fi
}

# 判断内存
get_mem () {
  local ram=$(grep ^MemTotal: /proc/meminfo | { read x y z; echo $y; }) || true # in kilobytes
  if [ -z "$ram" ]; then
          ram=0
  else
          ram=$(expr "$ram" / 1024) # convert to megabytes
  fi
  echo $ram
}

if [ $(get_mem) -lt $MEMLIMIT ] ; then
  echo "Too Low Memory Or Get Memory Failed..."
  exit 1
fi

# 选择镜像
function SelectMirror(){
  [ $# -ge 3 ] || exit 1
  Relese="$1"
  DIST=$(echo "$2" |sed 's/\ //g' |sed -r 's/(.*)/\L\1/')
  VER=$(echo "$3" |sed 's/\ //g' |sed -r 's/(.*)/\L\1/')
  New=$(echo "$4" |sed 's/\ //g')
  [ -n "$Relese" ] || exit 1
  [ -n "$DIST" ] || exit 1
  [ -n "$VER" ] || exit 1
  relese=$(echo $Relese |sed -r 's/(.*)/\L\1/')
  inUpdate=''; [ "$Relese" == "Ubuntu" ] && inUpdate='-updates'
  MirrorTEMP="SUB_MIRROR/dists/${DIST}${inUpdate}/main/installer-${VER}/current/images/netboot/${relese}-installer/${VER}/initrd.gz"
  [ -n "$MirrorTEMP" ] || exit 1
  # 声明数组 测试镜像可用性
  # 测个锤子，直接用
  # Debian的
  CurMirror="http://deb.debian.org/debian"
  # Ubuntu的
  # CurMirror="http://archive.ubuntu.com/ubuntu"
  echo "$CurMirror" || exit 1
}

# 设置默认
[ -n "$Relese" ] ||  Relese='Debian'

linux_relese=$(echo "$Relese" |sed 's/\ //g' |sed -r 's/(.*)/\L\1/')
clear && echo -e "\nCheck Dependence\n"

# 检查依赖
CheckDependence wget,awk,grep,sed,cut,cat,cpio,gzip,find,dirname,basename,unzip,openssl,findmnt,blkid,lsblk;

# 检测硬盘
dpart=$(findmnt -n -e -o SOURCE  /) || true
disk=$(lsblk -n -p -o PKNAME $dpart) || true
uuid=$(blkid $disk -o value -s UUID) || true
if [ -z "$disk" ]; then
  echo "Detect System Disk Failed..."
  exit 1
fi

# 确定引导grub/grub2
if [[ "$loaderMode" == "0" ]]; then
  [[ -f '/boot/grub/grub.cfg' ]] && GRUBVER='0' && GRUBDIR='/boot/grub' && GRUBFILE='grub.cfg';
  [[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub2/grub.cfg' ]] && GRUBVER='0' && GRUBDIR='/boot/grub2' && GRUBFILE='grub.cfg';
  [[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub/grub.conf' ]] && GRUBVER='1' && GRUBDIR='/boot/grub' && GRUBFILE='grub.conf';
  [ -z "$GRUBDIR" -o -z "$GRUBFILE" ] && echo -ne "Error! \nNot Found grub.\n" && exit 1;
else
  tmpINS='auto'
fi

# 选择架构
if [[ -n "$tmpVER" ]]; then
  tmpVER="$(echo "$tmpVER" |sed -r 's/(.*)/\L\1/')";
  if  [[ "$tmpVER" == '32' ]] || [[ "$tmpVER" == 'i386' ]] || [[ "$tmpVER" == 'x86' ]]; then
    VER='i386';
  fi
  if  [[ "$tmpVER" == '64' ]] || [[ "$tmpVER" == 'amd64' ]] || [[ "$tmpVER" == 'x86_64' ]] || [[ "$tmpVER" == 'x64' ]]; then
    if [[ "$Relese" == 'Debian' ]] || [[ "$Relese" == 'Ubuntu' ]]; then
      VER='amd64';
    elif [[ "$Relese" == 'CentOS' ]]; then
      VER='x86_64';
    fi
  fi
fi
[ -z "$VER" ] && VER='amd64'

if [[ -z "$tmpDIST" ]]; then
  [ "$Relese" == 'Debian' ] && tmpDIST='buster';
  # [ "$Relese" == 'Ubuntu' ] && tmpDIST='bionic' && DIST='bionic';
fi

# 选择镜像源目录
if [[ -z "$DIST" ]]; then
  if [[ "$Relese" == 'Debian' ]]; then
    SpikCheckDIST='0'
    DIST="$(echo "$tmpDIST" |sed -r 's/(.*)/\L\1/')";
    echo "$DIST" |grep -q '[0-9]';
    [[ $? -eq '0' ]] && {
      isDigital="$(echo "$DIST" |grep -o '[\.0-9]\{1,\}' |sed -n '1h;1!H;$g;s/\n//g;$p' |cut -d'.' -f1)";
      [[ -n $isDigital ]] && {
        [[ "$isDigital" == '9' ]] && DIST='stretch';
        [[ "$isDigital" == '10' ]] && DIST='buster';
      }
    }
    LinuxMirror=$(SelectMirror "$Relese" "$DIST" "$VER" "$tmpMirror")
  fi
  # 暂时删除对Ubuntu的支持
  if [[ "$Relese" == 'UUUUUUUUbuntu' ]]; then
    SpikCheckDIST='0'
    DIST="$(echo "$tmpDIST" |sed -r 's/(.*)/\L\1/')";
    echo "$DIST" |grep -q '[0-9]';
    [[ $? -eq '0' ]] && {
      isDigital="$(echo "$DIST" |grep -o '[\.0-9]\{1,\}' |sed -n '1h;1!H;$g;s/\n//g;$p')";
      [[ -n $isDigital ]] && {
        [[ "$isDigital" == '12.04' ]] && DIST='precise';
        [[ "$isDigital" == '14.04' ]] && DIST='trusty';
        [[ "$isDigital" == '16.04' ]] && DIST='xenial';
        [[ "$isDigital" == '18.04' ]] && DIST='bionic';
      }
    }
    LinuxMirror=$(SelectMirror "$Relese" "$DIST" "$VER" "$tmpMirror")
  fi
# 删除Centos7
fi

if [[ -z "$LinuxMirror" ]]; then
  echo -ne "\033[31mError! \033[0mInvaild mirror! \n"
  [ "$Relese" == 'Debian' ] && echo -en "\033[33mexample:\033[0m http://deb.debian.org/debian\n\n";
  # [ "$Relese" == 'Ubuntu' ] && echo -en "\033[33mexample:\033[0m http://archive.ubuntu.com/ubuntu\n\n";
  bash $0 error;
  exit 1;
fi

# 检查DIST的合理性
if [[ "$SpikCheckDIST" == '0' ]]; then
  DistsList="$(wget --no-check-certificate -qO- "$LinuxMirror/dists/" |grep -o 'href=.*/"' |cut -d'"' -f2 |sed '/-\|old\|Debian\|experimental\|stable\|test\|sid\|devel/d' |grep '^[^/]' |sed -n '1h;1!H;$g;s/\n//g;s/\//\;/g;$p')";
  for CheckDEB in `echo "$DistsList" |sed 's/;/\n/g'`
    do
      [[ "$CheckDEB" == "$DIST" ]] && FindDists='1' && break;
    done
  [[ "$FindDists" == '0' ]] && {
    echo -ne '\nThe dists version not found, Please check it! \n\n'
    bash $0 error;
    exit 1;
  }
fi

# 删除手动模式

# 如果都给了值就设置网络
[ -n "$ipAddr" ] && [ -n "$ipMask" ] && [ -n "$ipGate" ] && setNet='1';
[[ "$setNet" == '1' ]] && {
  IPv4="$ipAddr";
  MASK="$ipMask";
  GATE="$ipGate";
} || {
  echo "Please SetNet."
  exit 1;
}
# 设置密码
[[ -n "$tmpWORD" ]] && myPASSWORD="$(openssl passwd -1 "$tmpWORD")";
[[ -z "$myPASSWORD" ]] && echo "Please use -p xxx to set password for the new system." && exit 1;

# 设置接口名
if [[ -n "$interface" ]]; then
  IFETH="$interface"
fi
# 清屏 暂时注释
# clear && echo -e "\n\033[36m# Install\033[0m\n"

echo -e "Install\n"
echo -e "$Relese $DIST $VER Downloading..."


# 下载安装镜像
if [[ "$linux_relese" == 'debian' ]] || [[ "$linux_relese" == 'ubuntu' ]]; then
  inUpdate=''; [ "$linux_relese" == 'ubuntu' ] && inUpdate='-updates'
  # 修改图形化镜像
  wget --no-check-certificate -qO '/boot/initrd.img' "${LinuxMirror}/dists/${DIST}${inUpdate}/main/installer-${VER}/current/images/netboot/gtk/${linux_relese}-installer/${VER}/initrd.gz"
  [[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'initrd.img' for \033[33m$linux_relese\033[0m failed! \n" && exit 1
  wget --no-check-certificate -qO '/boot/vmlinuz' "${LinuxMirror}/dists/${DIST}${inUpdate}/main/installer-${VER}/current/images/netboot/gtk/${linux_relese}-installer/${VER}/linux"
  [[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'vmlinuz' for \033[33m$linux_relese\033[0m failed! \n" && exit 1
  MirrorHost="$(echo "$LinuxMirror" |awk -F'://|/' '{print $2}')";
  MirrorFolder="$(echo "$LinuxMirror" |awk -F''${MirrorHost}'' '{print $2}')";
else
  bash $0 error;
  exit 1;
fi
# 下载Firmware 如果需要的话
if [[ "$linux_relese" == 'debian' ]]; then
  if [[ "$IncFirmware" == '1' ]]; then
    wget --no-check-certificate -qO '/boot/firmware.cpio.gz' "http://cdimage.debian.org/cdimage/unofficial/non-free/firmware/${DIST}/current/firmware.cpio.gz"
    [[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'firmware' for \033[33m$linux_relese\033[0m failed! \n" && exit 1
  fi
fi

echo "下载完成"

# 判断是否为DHCP 删了 用锤子DHCP

# 修改引导
# 最麻烦的地方
# 分GRUB1和GRUB2
if [[ "$loaderMode" == "0" ]]; then
  [[ ! -f $GRUBDIR/$GRUBFILE ]] && echo "Error! Not Found $GRUBFILE. " && exit 1;

  # 备份引导文件
  [[ ! -f $GRUBDIR/$GRUBFILE.old ]] && [[ -f $GRUBDIR/$GRUBFILE.bak ]] && mv -f $GRUBDIR/$GRUBFILE.bak $GRUBDIR/$GRUBFILE.old;
  mv -f $GRUBDIR/$GRUBFILE $GRUBDIR/$GRUBFILE.bak;
  [[ -f $GRUBDIR/$GRUBFILE.old ]] && cat $GRUBDIR/$GRUBFILE.old >$GRUBDIR/$GRUBFILE || cat $GRUBDIR/$GRUBFILE.bak >$GRUBDIR/$GRUBFILE;
else
  GRUBVER='2'
fi

[[ "$GRUBVER" == '0' ]] && {
  READGRUB='/tmp/grub.read'
  cat $GRUBDIR/$GRUBFILE |sed -n '1h;1!H;$g;s/\n/%%%%%%%/g;$p' | sed 's/}"/!!!!!/g' | grep -om 1 'menuentry\ [^{]*{[^}]*}%%%%%%%' |sed 's/%%%%%%%/\n/g' | sed 's/!!!!!/}"/g'  >$READGRUB
  LoadNum="$(cat $READGRUB |grep -c 'menuentry ')"
  if [[ "$LoadNum" -eq '1' ]]; then
    cat $READGRUB |sed '/^$/d' >/tmp/grub.new;
  elif [[ "$LoadNum" -gt '1' ]]; then
    CFG0="$(awk '/menuentry /{print NR}' $READGRUB|head -n 1)";
    CFG2="$(awk '/menuentry /{print NR}' $READGRUB|head -n 2 |tail -n 1)";
    CFG1="";
    for tmpCFG in `awk '/}/{print NR}' $READGRUB`
      do
        [ "$tmpCFG" -gt "$CFG0" -a "$tmpCFG" -lt "$CFG2" ] && CFG1="$tmpCFG";
      done
    [[ -z "$CFG1" ]] && {
      echo "Error! read $GRUBFILE. ";
      exit 1;
    }

    sed -n "$CFG0,$CFG1"p $READGRUB >/tmp/grub.new;
    [[ -f /tmp/grub.new ]] && [[ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ]] || {
      echo -ne "\033[31mError! \033[0mNot configure $GRUBFILE. \n";
      exit 1;
    }
  fi
  [ ! -f /tmp/grub.new ] && echo "Error! $GRUBFILE. " && exit 1;
  sed -i "/menuentry.*/c\menuentry\ \'Install OS \[$DIST\ $VER\]\'\ --class debian\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ \{" /tmp/grub.new
  sed -i "/echo.*Loading/d" /tmp/grub.new;
  INSERTGRUB="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
}

[[ "$GRUBVER" == '1' ]] && {
  CFG0="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)";
  CFG1="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)";
  [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 == $CFG0 ] && sed -n "$CFG0,$"p $GRUBDIR/$GRUBFILE >/tmp/grub.new;
  [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 != $CFG0 ] && sed -n "$CFG0,$[$CFG1-1]"p $GRUBDIR/$GRUBFILE >/tmp/grub.new;
  [[ ! -f /tmp/grub.new ]] && echo "Error! configure append $GRUBFILE. " && exit 1;
  sed -i "/title.*/c\title\ \'Install OS \[$DIST\ $VER\]\'" /tmp/grub.new;
  sed -i '/^#/d' /tmp/grub.new;
  INSERTGRUB="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
}

if [[ "$loaderMode" == "0" ]]; then
[[ -n "$(grep 'linux.*/\|kernel.*/' /tmp/grub.new |awk '{print $2}' |tail -n 1 |grep '^/boot/')" ]] && Type='InBoot' || Type='NoBoot';

LinuxKernel="$(grep 'linux.*/\|kernel.*/' /tmp/grub.new |awk '{print $1}' |head -n 1)";
[[ -z "$LinuxKernel" ]] && echo "Error! read grub config! " && exit 1;
LinuxIMG="$(grep 'initrd.*/' /tmp/grub.new |awk '{print $1}' |tail -n 1)";
[ -z "$LinuxIMG" ] && sed -i "/$LinuxKernel.*\//a\\\tinitrd\ \/" /tmp/grub.new && LinuxIMG='initrd';

if [[ "$setInterfaceName" == "1" ]]; then
  Add_OPTION="net.ifnames=0 biosdevname=0";
else
  Add_OPTION="";
fi

if [[ "$setIPv6" == "1" ]]; then
  Add_OPTION="$Add_OPTION ipv6.disable=1";
fi

# 设置自动安装
echo "设置自动安装"

if [[ "$linux_relese" == 'debian' ]] || [[ "$linux_relese" == 'ubuntu' ]]; then
  BOOT_OPTION="vga=788 auto=true $Add_OPTION hostname=$linux_relese domain= -- quiet"
fi

[[ "$Type" == 'InBoot' ]] && {
  sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/boot\/vmlinuz $BOOT_OPTION" /tmp/grub.new;
  sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/boot\/initrd.img" /tmp/grub.new;
}

[[ "$Type" == 'NoBoot' ]] && {
  sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz $BOOT_OPTION" /tmp/grub.new;
  sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrd.img" /tmp/grub.new;
}

sed -i '$a\\n' /tmp/grub.new;
fi

GRUBPATCH='0';

if [[ "$loaderMode" == "0" ]]; then

sed -i ''${INSERTGRUB}'i\\n' $GRUBDIR/$GRUBFILE;
sed -i ''${INSERTGRUB}'r /tmp/grub.new' $GRUBDIR/$GRUBFILE;
[[ -f  $GRUBDIR/grubenv ]] && sed -i 's/saved_entry/#saved_entry/g' $GRUBDIR/grubenv;
fi

[[ -d /tmp/boot ]] && rm -rf /tmp/boot;
mkdir -p /tmp/boot;
cd /tmp/boot;

COMPTYPE="gzip";
UNCOMP='gzip -d';
NewIMG="initrd.img.gz"
mv -f "/boot/initrd.img" "/tmp/$NewIMG"

$UNCOMP < /tmp/$NewIMG | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1

# 放入VNC
wget -O /tmp/vnc.zip ${down_url}/vnc_${DIST}_${VER}.zip
unzip -d /tmp/boot/ /tmp/vnc.zip
chmod a+x /tmp/boot/usr/bin/x0vncserver
chmod a+x /tmp/boot/usr/sbin/vncsession
echo "/usr/bin/x0vncserver -securitytypes none &" >> /tmp/boot/lib/debian-installer.d/S62Xorg

# 放入硬盘选择
if [ ! -z "$uuid" ]; then
  echo $uuid > /tmp/boot/disk_uuid
fi
echo $disk > /tmp/boot/disk_dev

wget -O /tmp/boot/disk_select.sh ${down_url}/disk_select.sh
chmod a+x /tmp/boot/disk_select.sh

# 强制不进入低内存模式
# 内存是否足够的逻辑在脚本中进行
# 强行关闭低内存模式
sed -i 's/1024/1/' /tmp/boot/lib/debian-installer-startup.d/S15lowmem
# 强行开启Xorg
sed -i 's/return 1/return 0/' /tmp/boot/lib/debian-installer.d/S60frontend

# 设置自动安装选项
if [[ "$linux_relese" == 'debian' ]] || [[ "$linux_relese" == 'ubuntu' ]]; then
cat >/tmp/boot/preseed.cfg<<EOF
d-i debian-installer/locale string en_US
d-i console-setup/layoutcode string us

d-i keyboard-configuration/xkb-keymap string us

d-i netcfg/choose_interface select $IFETH

d-i netcfg/disable_autoconfig boolean true
d-i netcfg/dhcp_failed note
d-i netcfg/dhcp_options select Configure network manually
d-i netcfg/get_ipaddress string $IPv4
d-i netcfg/get_netmask string $MASK
d-i netcfg/get_gateway string $GATE
d-i netcfg/get_nameservers string 8.8.8.8 1.1.1.1
d-i netcfg/no_default_route boolean true
d-i netcfg/confirm_static boolean true

d-i hw-detect/load_firmware boolean true

d-i mirror/country string manual
d-i mirror/http/hostname string $MirrorHost
d-i mirror/http/directory string $MirrorFolder
d-i mirror/http/proxy string
d-i apt-setup/services-select multiselect

d-i passwd/root-login boolean ture
d-i passwd/make-user boolean false
d-i passwd/root-password-crypted password $myPASSWORD
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false

d-i clock-setup/utc boolean true
d-i time/zone string US/Eastern
d-i clock-setup/ntp boolean true

d-i partman/early_command string  \
debconf-set partman-auto/disk "\$(/disk_select.sh)"; \
debconf-set grub-installer/bootdev string "\$(/disk_select.sh)"; \

d-i partman/mount_style select uuid
d-i partman-auto/init_automatically_partition select Guided - use entire disk
d-i partman-auto/choose_recipe select All files in one partition (recommended for new users)
d-i partman-auto/method string regular
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

d-i debian-installer/allow_unauthenticated boolean true

tasksel tasksel/first multiselect minimal
d-i pkgsel/update-policy select none
d-i pkgsel/include string openssh-server
d-i pkgsel/upgrade select none

popularity-contest popularity-contest/participate boolean false

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default
d-i grub-installer/force-efi-extra-removable boolean true
d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/reboot boolean true
d-i preseed/late_command string	\
sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin yes/g' /target/etc/ssh/sshd_config; \
sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config; \
mkdir /target/var/log/VNCReInstall/; \
cp -R /var/log/ /target/var/log/VNCReInstall/;
EOF

[[ "$DIST" == 'xenial' ]] && {
  sed -i 's/^d-i\ clock-setup\/ntp\ boolean\ true/d-i\ clock-setup\/ntp\ boolean\ false/g' /tmp/boot/preseed.cfg
}

# 与vnc有关
[[ "$GRUBPATCH" == '0' ]] && {
  sed -i 's/debconf-set\ grub-installer\/bootdev.*\"\;//g' /tmp/boot/preseed.cfg
}

[[ "$linux_relese" == 'debian' ]] && {
  sed -i '/user-setup\/allow-password-weak/d' /tmp/boot/preseed.cfg
  sed -i '/user-setup\/encrypt-home/d' /tmp/boot/preseed.cfg
  sed -i '/pkgsel\/update-policy/d' /tmp/boot/preseed.cfg
}
[[ "$linux_relese" == 'debian' ]] && [[ -f '/boot/firmware.cpio.gz' ]] && {
  gzip -d < /boot/firmware.cpio.gz | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1
}

fi

find . | cpio -H newc --create --verbose | gzip -4 > /boot/initrd.img;
rm -rf /tmp/boot;

chown root:root $GRUBDIR/$GRUBFILE
chmod 444 $GRUBDIR/$GRUBFILE

if [[ "$loaderMode" == "0" ]]; then
  sleep 3 && reboot >/dev/null 2>&1
else
  rm -rf "$HOME/loader"
  mkdir -p "$HOME/loader"
  cp -rf "/boot/initrd.img" "$HOME/loader/initrd.img"
  cp -rf "/boot/vmlinuz" "$HOME/loader/vmlinuz"
  [[ -f "/boot/initrd.img" ]] && rm -rf "/boot/initrd.img"
  [[ -f "/boot/vmlinuz" ]] && rm -rf "/boot/vmlinuz"
  echo && ls -AR1 "$HOME/loader"
fi
