#!/bin/bash -ex
###############################################
# Script to apply changes to pi-topOS for LAUSD
###############################################

# Check required environment variables
required_vars=(
    "LAUSD_ROOT_CA2_CRT_CONTENT"
    "LAUSD_SUB_CA2_CRT_CONTENT"
    "LAUSD_ROOT_CA2_CRT_PATH"
    "LAUSD_SUB_CA2_CRT_PATH"
    "LAUSD_NETWORK_SSID"
    "LAUSD_NETWORK_SSID_ALTERNATE"
    "LAUSD_NETWORK_PASSWORD"
    "LAUSD_NETWORK_CONNECTION_FILE_FOLDER"
    "LAUSD_NETWORK_IDENTITY"
    "LAUSD_NETWORK_KEY_MGMT"
    "LAUSD_NETWORK_EAP"
    "LAUSD_NETWORK_PHASE2_AUTH"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
done

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

function install_certificates() {
    # Create certificate directory if it doesn't exist
    mkdir -p /usr/local/share/ca-certificates

    # Install the certificates
    echo "Installing LAUSD Root CA certificate..."
    echo -e "$LAUSD_ROOT_CA2_CRT_CONTENT" >$LAUSD_ROOT_CA2_CRT_PATH

    echo "Installing LAUSD sub CA certificate..."
    echo -e "$LAUSD_SUB_CA2_CRT_CONTENT" >$LAUSD_SUB_CA2_CRT_PATH
}

function create_network_connection_file() {
    ssid=$1
    local uuid=$(uuid)
    local connection_file="${LAUSD_NETWORK_CONNECTION_FILE_FOLDER}/${ssid}.nmconnection"
    cat >$connection_file <<EOF
[connection]
autoconnect=true
id=${ssid}
uuid=${uuid}
type=wifi
interface-name=wlan0

[wifi]
mode=infrastructure
ssid=${ssid}

[wifi-security]
key-mgmt=${LAUSD_NETWORK_KEY_MGMT}

[802-1x]
eap=${LAUSD_NETWORK_EAP}
identity=${LAUSD_NETWORK_IDENTITY}
password=${LAUSD_NETWORK_PASSWORD}
phase2-auth=${LAUSD_NETWORK_PHASE2_AUTH}

[ipv4]
method=auto

[ipv6]
addr-gen-mode=default
method=auto

[proxy]
EOF

    # Set proper permissions for file
    chmod 600 $connection_file
}

function update_ca_certificates() {
    echo "Updating CA certificates..."
    update-ca-certificates
}

function configure_network() {
    echo "Configuring network..."
    create_network_connection_file $LAUSD_NETWORK_SSID
    create_network_connection_file $LAUSD_NETWORK_SSID_ALTERNATE
}

function add_wifi_monitor() {
    echo "Installing wi-fi monitor..."
    apt update
    DEBIAN_FRONTEND=noninteractive apt-get install -y wi-fi-connect-monitor
    echo "Enabling wi-fi monitor for networks..."
    ESCAPED_SSIDS=$(systemd-escape "$LAUSD_NETWORK_SSID $LAUSD_NETWORK_SSID_ALTERNATE")
    systemctl enable wi-fi-connect-monitor@$ESCAPED_SSIDS.service
    systemctl start wi-fi-connect-monitor@$ESCAPED_SSIDS.service
}

function main() {
    install_certificates
    update_ca_certificates
    configure_network
    add_wifi_monitor
}

main
