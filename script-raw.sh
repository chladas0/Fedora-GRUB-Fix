#!/bin/bash

# !! This needs to be set up before running the script !!
BTRFS_UUID="708533e5-f4e3-48d7-9023-c05c1bb44bc2"            # Your root partition UUID
device="/dev/nvme0n1"                                        # EFI device name (not partition but the whole disk) 
partition="1"                                                # EFI partition number 
mount_point="/mnt"                                           # No need to change

mount -t btrfs -o subvol=root,compress=zstd:1 UUID=$BTRFS_UUID $mount_point

for fs in proc sys run dev sys/firmware/efi/efivars; do
    mkdir -p $mount_point/$fs
    mount -o bind /$fs $mount_point/$fs
done


chroot $mount_point /bin/bash << EOF


mount -a


dnf reinstall -y shim-* grub2-*


grub2-mkconfig -o /boot/grub2/grub.cfg


efibootmgr -c -d $device -p $partition -L FedoraTest -l '\\EFI\\fedora\\shimx64.efi'

EOF
