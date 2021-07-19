#!/bin/bash

echo "Resizing partition ${2} on ${1} with new end=${3}"

parted "${1}" ---pretend-input-tty <<EOF
resizepart
${2}
${3}
Yes
quit
EOF

echo "Done"
