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
focal ${ROOT} http://archive.ubuntu.com/ubuntu/ 

### === post debootstrap ===

cat << \EOF > ${ROOT}/etc/apt/sources.list
#deb http://archive.ubuntu.com/ubuntu focal main
deb http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse

deb http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse

deb http://archive.canonical.com/ubuntu focal partner
deb-src http://archive.canonical.com/ubuntu focal partner
EOF

cat << \EOF > ${ROOT}/etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
#GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
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
apt --fix-broken install -y
apt-get install -y aptitude tree initramfs-tools

apt-get install -y wget gnupg gnupg2

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list

apt-get update -y
apt-get install -y google-chrome-stable

aptitude upgrade -y
aptitude install language-pack-gnome-ja fonts-noto fonts-takao fonts-ipafont fonts-ipaexfont -y

locale-gen ja_JP.UTF-8
#update-locale LANG=ja_JP.UTF-8
update-locale LANG=C.UTF-8

aptitude clean 

useradd -mU ubuntu -G sudo -s /bin/bash 
echo "ubuntu:ubuntu" | chpasswd

echo "Asia/Tokyo" > /etc/timezone
ln -sf /usr/share/zoneinfo/Japan /etc/localtime

dconf write /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/use-system-font false


for d in /sys/fs/pstore /dev/pts /dev /sys /proc ; do
umount $d
done

EOF

chmod +x ${ROOT}/post_inst.sh
chroot ${ROOT} /bin/bash /post_inst.sh

(cd ${ROOT} ; tar --numeric-owner --acls --xattrs -cpf - .) | gzip > ${TOP_DIR}/${PKG}.tgz
