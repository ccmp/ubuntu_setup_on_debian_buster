#!/bin/bash 

TGZ=$1
dev=/dev/nvme0n1

TOP_DIR=${PWD}/Build
MNT_DIR=${PWD}/root

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

mkdir -p ${MNT_DIR}
mount -L ubuntu ${MNT_DIR}
mkdir -p ${MNT_DIR}/boot/efi
mount -L ESP ${MNT_DIR}/boot/efi

### === Exstract Rootfs ===

gunzip -c ${TOP_DIR}/${PKG}.tgz | (cd ${MNT_DIR} ; tar --numeric-owner --acls --xattrs -xvpf - )


### === Post Exstract Rootfs ===

cat << EOF > ${MNT_DIR}/boot/grub/grub.cfg_always

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


cat << EOF > ${MNT_DIR}/etc/netplan/01-netconfig.yaml 

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

cat << EOF > ${MNT_DIR}/etc/fstab 
${dev}p1  /               ext4    errors=remount-ro 0       1
LABEL=ESP	/boot/efi	vfat	defaults	0	0
EOF

cat << \EOF > ${MNT_DIR}/post_inst.sh
#!/bin/bash

mount -t proc none /proc/
mount -t sysfs none /sys/
mount -t devtmpfs none /dev/
mount -t devpts none /dev/pts/
mount -t pstore none /sys/fs/pstore/

apt-get update 
aptitude install -f
aptitude upgrade -y

aptitude install language-pack-gnome-ja fonts-noto fonts-takao fonts-ipafont fonts-ipaexfont -y
aptitude clean 

update-initramfs -c -k 5.4.0-26-generic
locale-gen ja_JP.UTF-8

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck --boot-directory=/boot/
update-grub

for d in /sys/fs/pstore /dev/pts /dev /sys /proc ; do
umount $d
done

EOF

chmod +x ${MNT_DIR}/post_inst.sh
chroot ${MNT_DIR} /bin/bash /post_inst.sh


