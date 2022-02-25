#!/bin/bash 

TOP_DIR=${PWD}/Build
MNT_DIR=${PWD}/root

case "$1" in 
	server|desktop)
		ROOT=${TOP_DIR}/ubuntu-$1
		PKG=ubuntu-$1
	;;
	*)
		echo Usage: $0 "[server|desktop] [sata|(nvme)]";
		exit
	;;
esac;

case "$2" in 
	sata)
	        dev=/dev/sda
	        part_root=/dev/sda1
	        part_efi=/dev/sda2	    
	;;
	nvme|"")
	        dev=/dev/nvme0n1
	        part_root=/dev/nvme0n1p1
	        part_efi=/dev/nvme0n1p2
	;;
	*)
	        echo Usage: $0 "[server|desktop] [sata|(nvme)]";
	        exit
	;;
	
esac;

apt-get update
apt-get install -y gdisk wget dosfstools parted 

ntpdate 0.debian.pool.ntp.org
hwclock -w

sgdisk -Z $dev
sgdisk -n 2::+512M  $dev
sgdisk -t 2:ef00 $dev
sgdisk -n 1:: $dev
sgdisk -c 1:Linux -c 2:ESP $dev
sgdisk -p $dev

sleep 10

partprobe

sleep 10

mkfs.fat -F32 -n efi ${part_efi}
mkfs.ext4 -F -L ubuntu ${part_root}

fatlabel ${part_efi} ESP

mkdir -p ${MNT_DIR}
mount -L ubuntu ${MNT_DIR}
mkdir -p ${MNT_DIR}/boot/efi
mount -L ESP ${MNT_DIR}/boot/efi

### === Download Package ===
if [ ! -f  ${TOP_DIR}/${PKG}.tgz ] ;then
  wget -P ${TOP_DIR} http://192.168.60.10:8088/install/${PKG}.tgz
  if [ $? -ne 0 ] ;then
    echo "Error: Cannot download rootfs:${PKG}.tgz"
    exit 1
  fi
else
  echo "rootfs:${PKG}.tgz is found. skip download..."
fi

### === Exstract Rootfs ===

echo -n "Extracting rootfs from ${TOP_DIR}/${PKG}.tgz ...."
gunzip -c ${TOP_DIR}/${PKG}.tgz | (cd ${MNT_DIR} ; tar --numeric-owner --acls --xattrs -xpf - )

echo " done"

### === Post Exstract Rootfs ===

cat << EOF > ${MNT_DIR}/boot/grub/grub.cfg_always

set default=0
set timeout=5

menuentry "Ubuntu Linux" {
linux /boot/vmlinuz root=${part_root} vga=0x305 panic=10
initrd /boot/initrd.img
}
menuentry "Ubuntu Linux Old" {
linux /boot/vmlinuz.old root=${part_root} vga=0x305 panic=10
}
EOF


cat << EOF > ${MNT_DIR}/etc/netplan/01-netconfig.yaml 

network:
  ethernets:
    enp72s0:
      dhcp4: yes
      dhcp6: no
  version: 2
EOF

cat << EOF > ${MNT_DIR}/etc/fstab 
${part_root}  /               ext4    errors=remount-ro 0       1
LABEL=ESP	/boot/efi	vfat	defaults	0	0
EOF

cp /etc/adjtime ${MNT_DIR}/etc/

cat << \EOF > ${MNT_DIR}/post_inst.sh
#!/bin/bash

mount -t proc none /proc/
mount -t sysfs none /sys/
mount -t devtmpfs none /dev/
mount -t devpts none /dev/pts/
mount -t pstore none /sys/fs/pstore/

aptitude install -f
aptitude upgrade -y
aptitude clean 

update-initramfs -c -k 5.4.0-26-generic

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck --boot-directory=/boot/
update-grub

for d in /sys/fs/pstore /dev/pts /dev /sys /proc ; do
umount $d
done

EOF

chmod +x ${MNT_DIR}/post_inst.sh
chroot ${MNT_DIR} /bin/bash /post_inst.sh
