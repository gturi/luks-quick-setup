#!/bin/bash

set -o errexit

lsblk


TARGET_DEVICE=""
while [[ -z "$TARGET_DEVICE" ]] || [[ ! -b "$TARGET_DEVICE" ]]; do
    read -p "Enter the device you want to encrypt via luks (i.e. /dev/sda): " TARGET_DEVICE
    if [[ -z "$TARGET_DEVICE" ]]; then
        >&2 echo "Error: input cannot be empty. Please try again."
    elif [[ ! -b "$TARGET_DEVICE" ]]; then
        >&2 echo "Error: input '$TARGET_DEVICE' is not a block device. Please try again."
    fi
done


echo "Creating luks device"
sudo cryptsetup luksFormat "$TARGET_DEVICE"

sudo cryptsetup isLuks "$TARGET_DEVICE"

echo "Successfully created luks device"


MY_DEVICE=luks-device

echo "Unlocking luks device"
sudo cryptsetup open "$TARGET_DEVICE" "$MY_DEVICE"

DEVICE_LABEL=""
while [[ -z "$DEVICE_LABEL" ]]; do
    read -p "Enter the device label (user friendly name to assign to the device): " DEVICE_LABEL
    if [[ -z "$DEVICE_LABEL" ]]; then
        >&2 echo "Error: input cannot be empty. Please try again."
    fi
done


echo "Creating btrfs filesystem"
sudo mkfs.btrfs -f -L "$DEVICE_LABEL" "/dev/mapper/$MY_DEVICE"

# TODO: change owner of the "/run/media/$USER/$DEVICE_LABEL"


LUKS_HEADER_BACKUP="$HOME/Desktop/$DEVICE_LABEL.luksHeaderBackup"

echo "Backupping LUKS headers at '$LUKS_HEADER_BACKUP'"
sudo cryptsetup luksHeaderBackup --header-backup-file "$LUKS_HEADER_BACKUP" "$TARGET_DEVICE"


echo "Changing owner of '$LUKS_HEADER_BACKUP' to $USER:$USER"
sudo chown "$USER:$USER" "$LUKS_HEADER_BACKUP"


echo "Done!"
