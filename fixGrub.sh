#!/bin/bash

# Use this script from live USB to fix your GRUB
# Before running this script ensure you have access to the internet
# Run lsblk -f to find out how your partitioning looks like

# Example output:
#
#   NAME        FSTYPE FSVER LABEL    UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
#   zram0                                                  [SWAP]
#   nvme0n1
#   ├─nvme0n1p1 vfat   FAT32          763B-8703                             579.5M     3% /boot/efi
#   ├─nvme0n1p2 ext4   1.0            5d96a62d-24b2-41ea-b869-f85cca146bff  493.5M    42% /boot
#   └─nvme0n1p3 btrfs        fedora   708533e5-f4e3-48d7-9023-c05c1bb44bc2  896.5G     6% /home
#
#
#
# Partition Overview:
#
#   nvme0n1p1 (EFI partition):
#     - Formatted as FAT32 (vfat).
#     - Contains the UEFI bootloader files (e.g., GRUB, Shim, or systemd-boot).
#     - UEFI firmware reads this partition during the boot process to locate and load the bootloader.
#     - Mounted at /boot/efi.
#
#   nvme0n1p2 (Boot partition):
#     - Formatted as ext4.
#     - Stores critical boot files, including:
#       - **Linux kernel**: The core component of the operating system, managing hardware and system processes.
#       - **initramfs (initial RAM filesystem)**: A temporary root filesystem loaded into memory by the bootloader.
#         - It initializes essential drivers and mounts the real root filesystem (e.g., nvme0n1p3).
#         - Provides support for filesystems or hardware not natively available in the kernel at boot time.
#     - Mounted at /boot.
#
#   nvme0n1p3 (Root filesystem partition):
#     - Formatted as Btrfs.
#     - Contains the root filesystem (/) with all operating system files, configurations, libraries, and user data.
#     - May also include separate subvolumes for directories like `/home`, `/var`, or `/tmp` to optimize storage management.
#

# !! This needs to be setup before running the script !! 
BTRFS_UUID="708533e5-f4e3-48d7-9023-c05c1bb44bc2"     # Your root partition
device="/dev/nvme0n1"                                 # EFI device name (not partition but the whole disk) 
partition="1"                                         # EFI partition number 
mount_point="/mnt"                                    # No need to change


# Exit if not run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use sudo or su." >&2
   exit 1
fi


# Mount the BTRFS subvolume `root` using UUID and apply zstd compression.
mount -t btrfs -o subvol=root,compress=zstd:1 UUID=$BTRFS_UUID $mount_point

# Check if the mount command was successful
if [[ $? -ne 0 ]]; then
    echo "Failed to mount BTRFS root subvolume. Check UUID and try again." >&2
    exit 1
fi

# Notify user that the subvolume was mounted
echo "BTRFS root subvolume mounted at $mount_point."


# Mount necessary system file systems
# Iterate over the required system file systems to bind-mount them into the new root.
for fs in proc sys run dev sys/firmware/efi/efivars; do

    # Ensure the target mountpoint exists, create if necessary
    mkdir -p $mount_point/$fs

    # Perform a bind mount for each required system directory
    mount -o bind /$fs $mount_point/$fs
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to bind mount $fs. Exiting." >&2
        exit 1
    fi
    
    # Confirm that the mount was successful
    echo "$fs mounted successfully."

done


# Now that all necessary file systems are mounted, chroot into the new root.
chroot $mount_point /bin/bash << EOF


# This ensures that file systems defined in /etc/fstab are mounted inside the chroot environment.
mount -a
if [[ $? -ne 0 ]]; then
    echo "Error mounting file systems defined in /etc/fstab." >&2
    exit 1
fi


# This reinstalls the bootloader and related packages (shim and grub2) in case of corruption.
dnf reinstall -y shim-* grub2-*
if [[ $? -ne 0 ]]; then
    echo "Failed to reinstall shim and grub2 packages." >&2
    exit 1
fi


# This command regenerates the GRUB configuration file to ensure the bootloader is correctly set up.
grub2-mkconfig -o /boot/grub2/grub.cfg
if [[ $? -ne 0 ]]; then
    echo "Failed to regenerate GRUB configuration." >&2
    exit 1
fi


# Reconfigure UEFI boot entry
# This creates a UEFI boot entry for Fedora with the correct path to the shimx64.efi bootloader.
efibootmgr -c -d $device -p $partition -L Fedora -l '\EFI\fedora\shimx64.efi.efi'

if [[ $? -ne 0 ]]; then
    echo "Failed to create UEFI boot entry." >&2
    exit 1
fi

EOF

# Notify the user that the process is completed successfully
echo "All steps completed successfully. GRUB should be repaired now."
