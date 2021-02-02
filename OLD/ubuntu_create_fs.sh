#!/bin/bash 

dev=/dev/nvme0n1
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

TOP_DIR=${PWD}
mkdir -p ${TOP_DIR}/root
mount -L ubuntu ${TOP_DIR}/root
mkdir -p ${TOP_DIR}/root/boot/efi
mount -L ESP ${TOP_DIR}/root/boot/efi

