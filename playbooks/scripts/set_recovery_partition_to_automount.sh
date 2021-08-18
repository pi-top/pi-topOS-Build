#!/bin/bash

PART_NUM_RECOVERY="01"

ROOT_PART_DEV=$(findmnt / -o source -n)
ROOT_PART_NAME=$(echo "$ROOT_PART_DEV" | cut -d "/" -f 3)
ROOT_DEV_NAME=$(echo /sys/block/*/"${ROOT_PART_NAME}" | cut -d "/" -f 4)
ROOT_DEV="/dev/${ROOT_DEV_NAME}"

IMGID="$(fdisk -l "$ROOT_DEV" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')"

# Remove existing entries for recovery
sed -i "s|PARTUUID=${IMGID}-${PART_NUM_RECOVERY}|d" /etc/fstab
echo "PARTUUID=${IMGID}-${PART_NUM_RECOVERY}  /recovery  vfat  defaults  0  2" >>/etc/fstab
