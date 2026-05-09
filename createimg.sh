#!/bin/bash

TOP_DIR=${PWD}/Build

case "$1" in
	server|desktop)
		ROOT=${TOP_DIR}/ubuntu-$1
		PKG=ubuntu-$1
	;;
	*)
		echo Usage: $0 "[server|desktop]";
		exit
	;;
esac;

mkdir -p ${ROOT}

ntpdate 0.debian.pool.ntp.org
hwclock -w

### === debootstrap ===

time debootstrap \
--include=${PKG},linux-image-generic,\
openssh-server,openssh-client,grub-efi \
noble ${ROOT} http://archive.ubuntu.com/ubuntu/

### === post debootstrap ===

cat << \EOF > ${ROOT}/etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse

deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF

cat << \EOF > ${ROOT}/etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX=""
GRUB_TERMINAL=console
GRUB_GFXMODE=640x480
EOF


cat << \EOF > ${ROOT}/post_inst.sh
#!/bin/bash

mount -t proc none /proc/
mount -t sysfs none /sys/
mount -t devtmpfs none /dev/
mount -t devpts none /dev/pts/
mount -t pstore none /sys/fs/pstore/

apt-get update -y
apt-get --fix-broken install -y
apt-get install -y aptitude tree initramfs-tools wget

apt-get upgrade -y
apt-get install -y language-pack-ja fonts-noto-cjk fonts-ipafont fonts-ipaexfont -y

locale-gen ja_JP.UTF-8
update-locale LANG=C.UTF-8

apt-get clean

useradd -mU ubuntu -G sudo -s /bin/bash
echo "ubuntu:ubuntu" | chpasswd

echo "Asia/Tokyo" > /etc/timezone
ln -sf /usr/share/zoneinfo/Japan /etc/localtime

for d in /sys/fs/pstore /dev/pts /dev /sys /proc ; do
umount $d
done

EOF

chmod +x ${ROOT}/post_inst.sh
chroot ${ROOT} /bin/bash /post_inst.sh

# Post install for ubuntu-desktop
if [ ${PKG}"x" = "ubuntu-desktopx" ] ;then

[ -d ${ROOT}/etc/dconf/profile ] || mkdir -p ${ROOT}/etc/dconf/profile
cat << \EOF > ${ROOT}/etc/dconf/profile/user
user-db:user
system-db:local
EOF

[ -d ${ROOT}/etc/dconf/db/local.d ] || mkdir -p ${ROOT}/etc/dconf/db/local.d
cat << \EOF > ${ROOT}/etc/dconf/db/local.d/01-gnome-terminal
[org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]

use-system-font=false
EOF

cat << \EOF > ${ROOT}/post_inst_desktop.sh
#!/bin/bash

mount -t proc none /proc/
mount -t sysfs none /sys/
mount -t devtmpfs none /dev/
mount -t devpts none /dev/pts/
mount -t pstore none /sys/fs/pstore/

mkdir -p /etc/apt/keyrings
wget -q -O /etc/apt/keyrings/google-chrome.asc https://dl-ssl.google.com/linux/linux_signing_key.pub
echo "deb [signed-by=/etc/apt/keyrings/google-chrome.asc] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

apt-get update -y
apt-get install -y google-chrome-stable

apt-get clean

/usr/bin/dconf update

for d in /sys/fs/pstore /dev/pts /dev /sys /proc ; do
umount $d
done

EOF

chmod +x ${ROOT}/post_inst_desktop.sh
chroot ${ROOT} /bin/bash /post_inst_desktop.sh

fi

(cd ${ROOT} ; tar --numeric-owner --acls --xattrs --xattrs-include='*' -cpf - .) | gzip > ${TOP_DIR}/${PKG}.tgz
