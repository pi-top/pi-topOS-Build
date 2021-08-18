#!/bin/bash
###############################################################
#                Unofficial 'Bash strict mode'                #
# http://redsymbol.net/articles/unofficial-bash-strict-mode/  #
###############################################################
set -euo pipefail
IFS=$'\n\t'
###############################################################

RECOVERY_PARTUUID="${1}-01"
MOUNT_TO="${2}"

# Remove existing entries for recovery
sed -i "s|PARTUUID=${RECOVERY_PARTUUID}|d" /etc/fstab
echo "PARTUUID=${RECOVERY_PARTUUID}  ${MOUNT_TO}  vfat  defaults  0  2" >>/etc/fstab
