#!/bin/bash 

dev=/dev/nvme0n1
TOP_DIR=${PWD}

sgdisk -Z $dev
sgdisk -n 2::+512M  $dev
sgdisk -t 2:ef00 $dev
sgdisk -n 1:: $dev
sgdisk -c 1:Linux -c 2:ESP $dev
sgdisk -p $dev
partprobe

mkfs.fat -F32 -n efi ${dev}p2
mkfs.ext4 -F -L ubuntu ${dev}p1

fatlabel ${dev}p2 ESP

mkdir -p ${TOP_DIR}/root
mount -L ubuntu ${TOP_DIR}/root
mkdir -p ${TOP_DIR}/root/boot/efi
mount -L ESP ${TOP_DIR}/root/boot/efi

### === debootstrap ===

time debootstrap \
--include=ubuntu-desktop,linux-image-generic,\
network-manager,\
openssh-server,openssh-client,grub-efi \
focal ./root/ http://archive.ubuntu.com/ubuntu/


### === post debootstrap ===

cat << \EOF > ${TOP_DIR}/root/etc/apt/sources.list
#deb http://archive.ubuntu.com/ubuntu focal main
deb http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse

deb http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse

deb http://archive.canonical.com/ubuntu focal partner
deb-src http://archive.canonical.com/ubuntu focal partner
EOF


cat << EOF > ${TOP_DIR}/root/boot/grub/grub.cfg_always

set default=0
set timeout=5

menuentry "Ubuntu Linux" {
linux /boot/vmlinuz root=/dev/${dev}p1 vga=0x305 panic=10 net.ifnames=0 biosdevname=0
initrd /boot/initrd.img
}
menuentry "Ubuntu Linux Old" {
linux /boot/vmlinuz.old root=/dev/${dev}p1 vga=0x305 panic=10 net.ifnames=0 biosdevname=0
}
EOF


cat << EOF > ${TOP_DIR}/root/etc/netplan/01-netconfig.yaml 

network:
  ethernets:
#    eth0:
    enp72s0:
#    enx567335da7a75:
      dhcp4: no
      addresses: [192.168.60.19/22]
      gateway4: 192.168.60.1
      nameservers:
        addresses: [192.168.60.1]
      dhcp6: no
  version: 2
EOF

cat << EOF > ${TOP_DIR}/root/etc/fstab 
${dev}p1  /               ext4    errors=remount-ro 0       1
LABEL=ESP	/boot/efi	vfat	defaults	0	0
EOF


cat << \EOF > ${TOP_DIR}/root/etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
#GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
GRUB_CMDLINE_LINUX=""
GRUB_TERMINAL=console
GRUB_GFXMODE=640x480
EOF


cat << \EOF > ${TOP_DIR}/root/post_inst.sh
#!/bin/bash

mount -t proc none /proc/
mount -t sysfs none /sys/
mount -t devtmpfs none /dev/
mount -t devpts none /dev/pts/
mount -t pstore none /sys/fs/pstore/


apt-get update 
apt --fix-broken install
apt-get install -y aptitude tree initramfs-tools

aptitude upgrade -y

update-initramfs -c -k 5.4.0-26-generic

aptitude install language-pack-gnome-ja fonts-noto fonts-takao fonts-ipafont fonts-ipaexfont -y

useradd -mU ubuntu -G sudo -s /bin/bash 
echo "ubuntu:ubuntu" | chpasswd

echo "Asia/Tokyo" > /etc/timezone
ln -sf /usr/share/zoneinfo/Japan /etc/localtime
locale-gen ja_JP.UTF-8
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck --boot-directory=/boot/
update-grub

EOF

chmod +x ${TOP_DIR}/root/post_inst.sh

