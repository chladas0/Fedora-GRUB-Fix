# GRUB Repair Script for Fedora (Live USB)

This script is specifically designed for **Fedora** users who need to repair their GRUB bootloader from a Live USB environment. It automates the process of mounting partitions, reinstalling bootloaders, regenerating GRUB configuration, and creating a UEFI boot entry.

## ⚠️ Prerequisites

Before running this script, ensure that:
- **You have internet access.**
- **You know your partition layout.** Run `lsblk -f` to identify your partitions. Below is an example output:

    ```
    NAME        FSTYPE FSVER LABEL    UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
    zram0                                                  [SWAP]
    nvme0n1
    ├─nvme0n1p1 vfat   FAT32          763B-8703                             579.5M     3% /boot/efi
    ├─nvme0n1p2 ext4   1.0            5d96a62d-24b2-41ea-b869-f85cca146bff  493.5M    42% /boot
    └─nvme0n1p3 btrfs        fedora   708533e5-f4e3-48d7-9023-c05c1bb44bc2  896.5G     6% /home
    ```

  Partition breakdown:
  - **EFI Partition** (`nvme0n1p1`): Contains UEFI bootloader files.
  - **Boot Partition** (`nvme0n1p2`): Stores critical boot files like the Linux kernel and initramfs.
  - **Root Partition** (`nvme0n1p3`): Contains the root filesystem with all OS files and user data.

## 🛠️ Setup

1. **Edit the script variables**:
   - Set your **BTRFS UUID**, **device** (e.g., `/dev/nvme0n1`), and **EFI partition number**.

2. **Set the flags**:
   - Set `variables_set_up=true` once the variables are properly configured.
   - Set `have_internet=true` after ensuring you have an active internet connection.

## 🚀 Running the Script

Run the script as `root`:

```bash
sudo ./grub_repair.sh
