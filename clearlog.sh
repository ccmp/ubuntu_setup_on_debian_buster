#!/bin/bash -eu

ROOTMNT=/mnt
IPMISEL=/usr/sbin/ipmi-sel
#BLKDEV=/dev/nvme0n1p1

case "$1" in 
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
	        echo Usage: $0 "[sata|(nvme)]";
	        exit
	;;
	
esac;

BLKDEV=${part_root}

if [ -b ${BLKDEV} ] ;then 
    mount ${BLKDEV} ${ROOTMNT}
else
    echo "Block Device not found:${BLKDEV}"
    exit
fi

echo "clean-up system logfile"
while read a
do
    echo "clean-up:$a"
    cp -f /dev/null $a
done < <(find ${ROOTMNT}/var/log/ -type f -name \*)

echo "clean-up bash history"
while read a
do
    echo "clean-up:$a"
    cp -f /dev/null $a
done < <(find ${ROOTMNT}/root ${ROOTMNT}/home -type f -name ".bash_history")

echo "clear IPMI System Event-Log"
${IPMISEL} --clear

