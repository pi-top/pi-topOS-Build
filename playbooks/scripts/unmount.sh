#!/bin/bash

unmount_root=$1

declare -a mount_points=("/proc" "/sys" "/dev" "/")

for point in "${mount_points[@]}"; do
	location="$unmount_root$point"
	if [ -d "$location" ]; then
		umount -rl "$location"
		echo "umount $location"
	else
		echo "$location doesn't exist"
	fi
done
