#!/bin/bash
###############################################################
#                Unofficial 'Bash strict mode'                #
# http://redsymbol.net/articles/unofficial-bash-strict-mode/  #
###############################################################
set -euo pipefail
IFS=$'\n\t'
###############################################################

set -x

readonly new_image_file=./new-image.img
# ID_RECOVERY="p1"
# ID_EXTENDED="p2"
ID_BOOT="p5"
ID_ROOTFS="p6"

echo "=== Creating image metadata file ==="

BOOT_START=$(fdisk -l -o Device,Start,Sectors "${new_image_file}" | grep "${new_image_file}${ID_BOOT: -1}" | awk '{ print $2}')
BOOT_SIZE=$(fdisk -l -o Device,Start,Sectors "${new_image_file}" | grep "${new_image_file}${ID_BOOT: -1}" | awk '{ print $3}')
ROOTFS_START=$(fdisk -l -o Device,Start,Sectors "${new_image_file}" | grep "${new_image_file}${ID_ROOTFS: -1}" | awk '{ print $2}')
ROOTFS_SIZE=$(fdisk -l -o Device,Start,Sectors "${new_image_file}" | grep "${new_image_file}${ID_ROOTFS: -1}" | awk '{ print $3}')

OS_METADATA_FILE="/tmp/metadata.txt"

if [ -f $OS_METADATA_FILE ]; then
	rm "${OS_METADATA_FILE}"
fi

echo "# pi-topOS metadata file. This file should be included alongside"
echo "# pi-topOS img file in zip file"
cat <<EOF >$OS_METADATA_FILE
# Partition logic
BOOT_START=${BOOT_START}
BOOT_SIZE=${BOOT_SIZE}
ROOTFS_START=${ROOTFS_START}
ROOTFS_SIZE=${ROOTFS_SIZE}

# Upgrade logic
LOADER_MINIMUM_VERSION=1
EOF

echo "*** metadata.txt contents: ***"
cat "${OS_METADATA_FILE}"
