#!/bin/bash -eu

ROOTMNT=/mnt
IPMISEL=/usr/sbin/ipmi-sel
NVMEBLKDEV=/dev/nvme0n1p1

if [ -b ${NVMEBLKDEV} ] ;then 
    mount /dev/nvme0n1p1 ${ROOTMNT}
else
    echo "Nvme Block Device not found:${NVMEBLKDEV}"
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

