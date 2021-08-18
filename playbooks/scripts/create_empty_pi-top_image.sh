#!/bin/bash -ex

##############################################################################
# Used to create a pi-topOS image with a
# recovery/bootloader partition
##############################################################################

# High level flow
# 1. Create empty image
# 2. Calculate file system offsets
# 3. Partition image
# 4. Mount image, maybe replace with Ansible

# Folders and image locations
readonly base_os_dir="/tmp/raspi-os"
readonly pi_top_dir="/tmp/pi-top-os"
readonly new_image_file=./new-image.img

function get_loop_devices_associated_with_file() {
	# Need to ignore deleted, since they still show up
	losetup --all | grep "$1" | grep -v deleted | cut -d: -f 1
}

# Check that Raspberry Pi OS image has been mounted correctly
if [ ! -d "$base_os_dir/boot/" ]; then
	printf "%s/boot/ doesn't exist, \nIt needs to be mounted into a flat file system since the copy is an rsync. \nParitions not mounted into / will be ignored" "$base_os_dir"
	exit
fi
echo "=== Cleaning up any existing temp files ==="
# Detach a loopback device from a file, first unmounting any partitions that
# were mounted.

echo "=== Checking if ${new_image_file} is already mounted ==="
if mount | grep -q "$pi_top_dir"; then
	umount --detach-loop --recursive "$pi_top_dir"
else
	echo "Nothing to unmount"
fi

# We force a delete here since lets assume this is a destructive operation
rm --force "$new_image_file"

echo "=== Unmounting system points on Raspberry Pi OS, required if they have been left mounted from Chrooting ==="
# TODO this should check if these points have been mounted first rather than blindly unmounting them
declare -a mount_points=("/proc" "/sys" "/dev")
for point in "${mount_points[@]}"; do
	location="$base_os_dir$point"
	if [ -d "$location" ]; then

		umount "$location" || true
		echo "umount $location"
	else
		echo "$location doesn't exist"
	fi
done

echo "=== Calculating and setting required partition sizes ==="
set -x
# Partition IDs on image with bootloader (p2 is an extended partition)
ID_RECOVERY="p1"
ID_EXTENDED="p2"
ID_BOOT="p5"
ID_ROOTFS="p6"

SECTOR_SIZE=512

# Set size of /recovery to 128MB
size_of_recovery=$((1024 * 1024 * 128))

# Set size of /boot to 256MB
size_of_boot=$((1024 * 1024 * 256))

# Set rootfs to 13GB to avoid running out of space during an update
size_of_rootfs=$((1024 * 1024 * 1024 * 13))

echo "size_of_recovery ${size_of_recovery} bytes"
echo "size_of_boot ${size_of_boot} bytes"
echo "size_of_rootfs ${size_of_rootfs} bytes "

# Sectors = bytes / sector_size

number_of_sectors_for_recovery=$((size_of_recovery / SECTOR_SIZE))
number_of_sectors_for_boot=$((size_of_boot / SECTOR_SIZE))

FIRST_USABLE_SECTOR=8192   # This seems to be a constant (leaving space for mbr?)
LOGICAL_PARTITION_GAP=2048 # There is a small gap between each logical partition (presumable some definition data or similar)

# Calculate the size of the image to create (the sum of all partitions and gaps)

IMAGE_SIZE=$((FIRST_USABLE_SECTOR + size_of_recovery + LOGICAL_PARTITION_GAP + size_of_boot + LOGICAL_PARTITION_GAP + size_of_rootfs))

# Round the image size to the nearest sector

IMAGE_SIZE=$((IMAGE_SIZE + SECTOR_SIZE - IMAGE_SIZE % SECTOR_SIZE))

# Calculate the parameters for fdisk

PARTITION_START_RECOVERY=${FIRST_USABLE_SECTOR}
PARTITION_END_RECOVERY=$((PARTITION_START_RECOVERY + number_of_sectors_for_recovery))
PARTITION_START_EXTENDED=$((PARTITION_END_RECOVERY + 1))
PARTITION_START_BOOT=$((PARTITION_START_EXTENDED + LOGICAL_PARTITION_GAP))
PARTITION_END_BOOT=$((PARTITION_START_BOOT + number_of_sectors_for_boot))
PARTITION_START_ROOTFS=$((PARTITION_END_BOOT + LOGICAL_PARTITION_GAP + 1))

echo "Partition parameters to be used in fdisk:"

echo "PARTITION_START_RECOVERY: ${PARTITION_START_RECOVERY}"
echo "PARTITION_END_RECOVERY: ${PARTITION_END_RECOVERY}"
echo "PARTITION_START_EXTENDED: ${PARTITION_START_EXTENDED}"
echo "PARTITION_START_BOOT: ${PARTITION_START_BOOT}"
echo "PARTITION_END_BOOT: ${PARTITION_END_BOOT}"
echo "PARTITION_START_ROOTFS: ${PARTITION_START_ROOTFS}"
echo "PARTITION_END_PT_ROOTFS: (fills the rest of the image, for expanding later)"
echo "Total image size: ${IMAGE_SIZE} bytes"

echo "=== Creating image file buffer ==="

fallocate --length ${IMAGE_SIZE} "${new_image_file}"

echo "=== Creating partition table using fdisk ==="

set -x
# NOTE THIS IS SUPER BRITTLE
# It's piping commands to fdisk which is why Raspberry Pi OS stopped doing it like this

fdisk "${new_image_file}" <<EOF
n
p
${ID_RECOVERY: -1}
${PARTITION_START_RECOVERY}
${PARTITION_END_RECOVERY}
n
e
${ID_EXTENDED: -1}
${PARTITION_START_EXTENDED}

n
l
${PARTITION_START_BOOT}
${PARTITION_END_BOOT}
n
l
${PARTITION_START_ROOTFS}

t
${ID_RECOVERY: -1}
e
t
${ID_BOOT: -1}
c
w
EOF

echo "=== Creating lodevice for new image ==="

# Create a loopback device using an image file. If a device alread exists
# for that file, it will be detached first.
loop_devices_attached_new_image=$(get_loop_devices_associated_with_file "${new_image_file}")

for loop_device in $loop_devices_attached_new_image; do
	losetup --detach "$loop_device"
	echo "detached $loop_device"
done

# This adds a new device for the image file
losetup --partscan --find "${new_image_file}"
new_loop_device=$(get_loop_devices_associated_with_file "${new_image_file}")
echo "New loopback device created: ${new_loop_device}"

echo "=== Making file system for recovery ==="

mkfs.fat -n recovery -F 16 -v -I "${new_loop_device}${ID_RECOVERY}"

echo "=== Making boot file system for ptos ==="

mkfs.fat -n boot -F 32 -v -I "${new_loop_device}${ID_BOOT}"

echo "=== Generating list of unsupported options for ext4 fs ==="

# When attempting to boot the rootfs partition, some of the default filesystem options
# of ext4 are not supported, e.g. 64bit, metadata_csum, huge_file, so we build a list
# of these (negated) to pass into mkfs.ext4

root_features="^huge_file"
for feature in metadata_csum 64bit; do
	if grep -q "$feature" /etc/mke2fs.conf; then
		root_features="^$feature,$root_features"
	fi
done

echo "Options: ${root_features}" # Should result in '^64bit,^metadata_csum,^huge_file', see https://ext4.wiki.kernel.org/index.php/Ext4_Metadata_Checksums

echo "=== Making rootfs file systems for ptos ==="

mkfs.ext4 -L rootfs -O "${root_features}" "${new_loop_device}${ID_ROOTFS}"

######################################################################################
echo "=== Mounting new image ==="

mkdir -p "${pi_top_dir}"
mount -v "${new_loop_device}${ID_ROOTFS}" "${pi_top_dir}" -t ext4

mkdir -p "${pi_top_dir}/recovery"
mount -v "${new_loop_device}${ID_RECOVERY}" "${pi_top_dir}/recovery" -t vfat

mkdir -p "${pi_top_dir}/boot"
mount -v "${new_loop_device}${ID_BOOT}" "${pi_top_dir}/boot" -t vfat

echo "=== Copying OS files to new image ==="
echo "Rsyncing from $base_os_dir to $pi_top_dir"
rsync --archive \
	--hard-links \
	--acls \
	--xattrs \
	--human-readable \
	--stats \
	"$base_os_dir/" "${pi_top_dir}/"

#      --one-file-system \
#      --exclude=var/cache/apt/archives \
set -x
echo "=== Creating fstab and boot/cmdline.txt"

# Partition numbers on image with bootloader
PART_NUM_RECOVERY="01"
# PART_NUM_EXTENDED="02"
PART_NUM_BOOT="05"
PART_NUM_ROOTFS="06"

IMGID="$(dd if="${new_image_file}" skip=440 bs=1 count=4 2>/dev/null | xxd -e | cut -f 2 -d' ')"

RECOVERY_PARTUUID="${IMGID}-${PART_NUM_RECOVERY}"
BOOT_PARTUUID="${IMGID}-${PART_NUM_BOOT}"
ROOT_PARTUUID="${IMGID}-${PART_NUM_ROOTFS}"

echo "Original /etc/fstab :"
cat "${pi_top_dir}/etc/fstab"

cat <<EOF >"${pi_top_dir}/etc/fstab"
proc            /proc           proc    defaults          0       0
PARTUUID=${BOOT_PARTUUID}  /boot           vfat    defaults          0       2
PARTUUID=${ROOT_PARTUUID}  /               ext4    defaults,noatime  0       1
PARTUUID=${RECOVERY_PARTUUID}  /recovery  vfat  defaults  0  2
EOF

echo "New /etc/fstab :"
cat "${pi_top_dir}/etc/fstab"

# Patch cmdline.txt with UUID
sed -i "s/root=PARTUUID.* /root=PARTUUID=${ROOT_PARTUUID} /1" "${pi_top_dir}/boot/cmdline.txt"

echo "New /boot/cmdline.txt :"
cat "${pi_top_dir}/boot/cmdline.txt"
