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

### === debootstrap ===

time debootstrap \
--include=${PKG},linux-image-generic,\
network-manager,\
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

apt-get update 
apt --fix-broken install -y
apt-get install -y aptitude tree initramfs-tools

aptitude upgrade -y
update-initramfs -c -k 5.4.0-26-generic

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

