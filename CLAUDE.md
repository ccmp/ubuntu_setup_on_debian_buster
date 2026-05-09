# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo provides shell scripts to build and deploy Ubuntu 20.04 (Focal) images onto bare-metal servers from a Debian Buster host environment.

## Workflow Overview

Three-phase process, each run as root:

### Phase 1 — Prepare the Debian Buster build host
```bash
./prep.sh
```
Adds Debian testing/unstable APT sources (pinned below stable) and installs `debootstrap` + `ubuntu-keyring` from testing. Required before `createimg.sh` can run.

### Phase 2 — Build a rootfs tarball (optional if image server is available)
```bash
./createimg.sh [server|desktop]
```
- Uses `debootstrap` to bootstrap Ubuntu Focal into `./Build/ubuntu-{server|desktop}/`
- Runs a `chroot` post-install script to add packages, create the `ubuntu` user, set timezone
- Desktop variant additionally installs Google Chrome inside the chroot
- Outputs `./Build/ubuntu-{server|desktop}.tgz`

### Phase 3 — Install onto target hardware
```bash
./ubuntu_install.sh [server|desktop] [sata|nvme]
```
- `sata` → `/dev/sda`; `nvme` (default) → `/dev/nvme0n1`
- Partitions disk with `sgdisk`: partition 1 = ext4 root, partition 2 = 512MB EFI
- Downloads `ubuntu-{server|desktop}.tgz` from `http://192.168.60.10:8088/install/` if not present locally in `./Build/`
- Extracts rootfs, writes netplan config, fstab, grub.cfg, then chroots to install GRUB EFI and run `update-grub`
- Errors during install do not abort the script — always inspect logs for partial failures

### Post-delivery cleanup
```bash
./clearlog.sh [sata|nvme]
```
Mounts the installed root partition, wipes all files under `/var/log/`, clears `.bash_history` for all users, and clears the IPMI/BMC System Event Log via `ipmi-sel --clear`.

## Key Constraints

- All scripts must run as **root** on the target/build host.
- `createimg.sh` and `ubuntu_install.sh` call `ntpdate` to sync the clock before heavy operations — the host must have network access.
- The internal image server (`192.168.60.10:8088`) is only reachable on the private network; place a pre-built `.tgz` in `./Build/` to skip the download.
- The installed Ubuntu default credentials are `ubuntu` / `ubuntu`.
- Netplan is configured for a single NIC (`enp72s0`) with DHCP; adjust for other NIC names before deploying to different hardware.
- `ubuntu_install.sh` hardcodes `initrd` version `5.4.0-26-generic` in `update-initramfs` — update this when the kernel version changes.

## Repository Layout

| File | Role |
|------|------|
| `prep.sh` | One-time Debian host setup |
| `createimg.sh` | Build Ubuntu rootfs tarball |
| `ubuntu_install.sh` | Partition, extract, and configure target disk |
| `clearlog.sh` | Pre-shipment log/history wipe |
| `trwk_readme.md` | End-user manual (Japanese) for the installed system |
| `OLD/` | Archived earlier versions of the scripts |
