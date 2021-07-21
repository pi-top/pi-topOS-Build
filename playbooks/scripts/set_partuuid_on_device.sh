#!/bin/bash -ex

echo "Applying PARTUUID=${2} to ${1}"

fdisk "${1}" <<EOF >/dev/null
p
x
i
0x${2}
r
p
w
EOF
