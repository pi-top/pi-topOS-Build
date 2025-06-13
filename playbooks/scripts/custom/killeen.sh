#!/bin/bash -ex
#################################################
# Script to apply changes to pi-topOS for Killeen
#################################################

# Check required environment variables
required_vars=(
    "KILLEEN_NETWORK_SSID"
    "KILLEEN_NETWORK_PASSWORD"
    "KILLEEN_PI_USER_PASSWORD"
    "KILLEEN_NTP_SERVER"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
done

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

function no_sudo_access_for_pi_user() {
    echo "Removing sudo access for pi user..."
    rm -f /etc/sudoers.d/010_pi-nopasswd

    # ensure pi not in sudoers
    deluser pi sudo
}

function remove_packages() {
    echo "Removing packages..."
    apt remove -y --purge \
        openssh-server \
        realvnc-vnc-server
    apt autoremove -y
}

function set_custom_ntp_server() {
    echo "Setting custom NTP server..."
    local ntp_conf_file="/etc/systemd/timesyncd.conf"
    # Use custom NTP server
    sed -i '/^#NTP=/c\NTP='$KILLEEN_NTP_SERVER "$ntp_conf_file"
}

function dont_allow_usb_storage() {
    echo "Creating udev rule to block USB storage devices..."
    local udev_rule_file="/etc/udev/rules.d/99-block-usb-storage.rules"

    # Create udev rule to block USB storage devices
    cat >"$udev_rule_file" <<'EOF'
# Block USB storage devices
ACTION=="add", SUBSYSTEMS=="usb", ATTRS{bInterfaceClass}=="08", ATTRS{bInterfaceSubClass}=="06", RUN+="/bin/sh -c 'logger \"Blocked USB storage device: SCSI transparent command set (\$kernel)\" && echo 0 > /sys/\$devpath/authorized'"
ACTION=="add", SUBSYSTEMS=="usb", ATTRS{bInterfaceClass}=="08", ATTRS{bInterfaceSubClass}=="05", RUN+="/bin/sh -c 'logger \"Blocked USB storage device: USB Attached SCSI (\$kernel)\" && echo 0 > /sys/\$devpath/authorized'"
ACTION=="add", SUBSYSTEMS=="usb", ATTRS{bInterfaceClass}=="08", ATTRS{bInterfaceSubClass}=="04", RUN+="/bin/sh -c 'logger \"Blocked USB storage device: UFI (\$kernel)\" && echo 0 > /sys/\$devpath/authorized'"
EOF

    # Ensure the file has correct permissions
    chmod 644 "$udev_rule_file"
}

function set_pi_user_password() {
    echo "Setting new pi user password..."
    # This could work, but will get overriden by the first boot setup script which sets the password to the one in the userconf file
    # echo "pi:$KILLEEN_PI_USER_PASSWORD" | chpasswd

    # TODO: this might not work on systemd-nspawn since /boot is not mounted...
    SALTED_PI_USER_PASSWORD=$(echo 'pi-top' | openssl passwd -5 -stdin -salt 'SomeSalt')
    echo "pi:$SALTED_PI_USER_PASSWORD" >/boot/firmware/userconf
}

function add_wifi_connection() {
    echo "Adding WiFi connection..."
    local conn_file="/etc/NetworkManager/system-connections/${KILLEEN_NETWORK_SSID}.nmconnection"

    # Generate connection UUID
    local uuid=$(uuid -v4)

    # Create the connection file
    cat >"$conn_file" <<'EOF'
[connection]
id=${KILLEEN_NETWORK_SSID}
uuid=${uuid}
type=wifi
interface-name=wlan0
autoconnect=true

[wifi]
mode=infrastructure
ssid=${KILLEEN_NETWORK_SSID}

[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=${KILLEEN_NETWORK_PASSWORD}

[ipv4]
method=auto

[ipv6]
method=auto

[proxy]
EOF

    sed -i "s/\${KILLEEN_NETWORK_SSID}/$KILLEEN_NETWORK_SSID/" "$conn_file"
    sed -i "s/\${KILLEEN_NETWORK_PASSWORD}/$KILLEEN_NETWORK_PASSWORD/" "$conn_file"
    sed -i "s/\${uuid}/$uuid/" "$conn_file"

    # Set correct permissions
    chmod 600 "$conn_file"
}

function disable_ethernet() {
    echo "Disabling ethernet interface..."
    mkdir -p /etc/network/interfaces.d/
    cat >"/etc/network/interfaces.d/eth0" <<'EOF'
# Disable eth0 interface
iface eth0 inet manual
    pre-up /bin/false
EOF
}

function block_other_networks() {
    echo "Blocking other wi-fi networks..."

    mkdir -p /etc/NetworkManager/dispatcher.d/
    cat >"/etc/NetworkManager/dispatcher.d/99-block-other-networks" <<'EOF'
#!/bin/bash

IFACE="$1"
STATUS="$2"
ALLOWED_SSID="${KILLEEN_NETWORK_SSID}"

if [ "$IFACE" = "wlan0" ] && [ "$STATUS" = "up" ]; then
    CURRENT_SSID=$(iw dev wlan0 link | grep SSID | awk '{print $2}')
    if [ "$CURRENT_SSID" != "$ALLOWED_SSID" ]; then
        logger "Disconnecting from unauthorized SSID: $CURRENT_SSID"
        nmcli device disconnect wlan0
    fi
fi
EOF
    # make executable
    chmod +x "/etc/NetworkManager/dispatcher.d/99-block-other-networks"

    # Replace placeholder with actual SSID
    sed -i "s/\${KILLEEN_NETWORK_SSID}/$KILLEEN_NETWORK_SSID/" "/etc/NetworkManager/dispatcher.d/99-block-other-networks"
}

function set_timezone() {
    # XXX: host machine needs to be in America/Chicago timezone for this to work.
    # This change might not take effect until the device is connected to a network...
    echo "Setting timezone to America/Chicago (Central Time)..."
    raspi-config nonint do_change_timezone America/Chicago
}

function remove_unstable_apt_repos() {
    echo "Removing pi-top unstable apt repos..."
    # 'disable' pt-unattended-upgrades to avoid issues when running apt
    # Move /etc/apt/apt.conf.d/60unattended-upgrades to /tmp
    mv /etc/apt/apt.conf.d/60unattended-upgrades /tmp/60unattended-upgrades

    # Mark as manually installed
    apt install -y pi-top-os-apt-source
    # Remove non-stable repos
    apt purge -y pi-top-os-unstable-apt-source pi-top-os-testing-apt-source

    # Restore /etc/apt/apt.conf.d/60unattended-upgrades
    mv /tmp/60unattended-upgrades /etc/apt/apt.conf.d/60unattended-upgrades
}

function disable_pt_web_vnc_service() {
    echo "Disabling pt-web-vnc-desktop service..."
    systemctl disable pt-web-vnc-desktop
    systemctl mask pt-web-vnc-desktop
}

function main() {
    no_sudo_access_for_pi_user
    remove_packages
    set_custom_ntp_server
    dont_allow_usb_storage
    set_pi_user_password
    add_wifi_connection
    disable_ethernet
    block_other_networks
    set_timezone
    remove_unstable_apt_repos
    disable_pt_web_vnc_service
}

main
