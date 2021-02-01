#!/bin/bash

TOP_DIR=${PWD}
mkdir -p ${TOP_DIR}/root
mount -L ubuntu ${TOP_DIR}/root
mkdir -p ${TOP_DIR}/root/boot/efi
mount -L ESP ${TOP_DIR}/root/boot/efi

mount -L efi /boot/efi/

