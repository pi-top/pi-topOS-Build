#!/bin/bash
###############################################################
#                Unofficial 'Bash strict mode'                #
# http://redsymbol.net/articles/unofficial-bash-strict-mode/  #
###############################################################
set -euo pipefail
IFS=$'\n\t'
###############################################################

PART_NUM_RECOVERY="01"

DISK_IDENTIFIER="${1}"

# Remove existing entries for recovery
sed -i "s|PARTUUID=${DISK_IDENTIFIER}-${PART_NUM_RECOVERY}|d" /etc/fstab
echo "PARTUUID=${DISK_IDENTIFIER}-${PART_NUM_RECOVERY}  /recovery  vfat  defaults  0  2" >>/etc/fstab
