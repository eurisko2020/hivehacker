#!/bin/sh
#
# generate-ssid.sh — Generate unique Wi-Fi SSID and SSH password from device serial
#
# Wi-Fi SSID: hivehackerXXXX (last 4 hex of serial)
# Wi-Fi password: hivehak!
# SSH root password: hivehacksshXXXX (different from Wi-Fi password)
#

HOSTAPD_CONF="/etc/hostapd.conf"
DEFAULT_WIFI_PASSWORD=*** the CPU serial number
SERIAL=""
if [ -f /sys/firmware/devicetree/base/serial-number ]; then
    SERIAL=$(cat /sys/firmware/devicetree/base/serial-number | tr -d '\0')
elif grep -q "^Serial" /proc/cpuinfo 2>/dev/null; then
    SERIAL=$(grep "^Serial" /proc/cpuinfo | awk '{print $3}' | sed 's/^0*//')
fi

# Fallback: use MAC address of wlan0 if serial not available
if [ -z "$SERIAL" ] || [ "$SERIAL" = "0000000000000000" ]; then
    if [ -f /sys/class/net/wlan0/address ]; then
        MAC=$(cat /sys/class/net/wlan0/address | tr -d ':' | tail -c 5)
        SERIAL="$MAC"
    else
        SERIAL="0000"
    fi
fi

# Extract last 4 characters of serial, uppercase
SSID_SUFFIX=$(echo "$SERIAL" | tail -c 5 | tr 'a-f' 'A-F')
SSID="hivehacker${SSID_SUFFIX}"
SSH_PASSWORD="hivehackssh${SSID_SUFFIX}"

echo "Generated SSID: $SSID"
echo "Generated SSH password: $SSH_PASSWORD"
echo "Serial: $SERIAL"

# Update hostapd.conf with the unique SSID and Wi-Fi password
if [ -f "$HOSTAPD_CONF" ]; then
    sed -i "s/^ssid=.*/ssid=$SSID/" "$HOSTAPD_CONF"
    sed -i "s/^wpa_passphrase=.*/wpa_passphrase=$DEFAULT_WIFI_PASSWORD/" "$HOSTAPD_CONF"
    echo "Updated $HOSTAPD_CONF with SSID=$SSID"
else
    echo "WARNING: $HOSTAPD_CONF not found"
fi

# Set the root password for SSH access
# Using chpasswd to set the password non-interactively
echo "root:${SSH_PASSWORD}" | chpasswd 2>/dev/null || {
    # Fallback if chpasswd not available
    echo "Setting password via passwd..."
    passwd root << EOF
${SSH_PASSWORD}
${SSH_PASSWORD}
EOF
}
echo "Root password set to: $SSH_PASSWORD"

# Write generated values to files for the web UI to read
mkdir -p /mnt/data/config
echo "$SSID" > /mnt/data/config/generated_ssid.txt
echo "$DEFAULT_WIFI_PASSWORD" > /mnt/data/config/generated_wifi_password.txt
echo "$SSH_PASSWORD" > /mnt/data/config/generated_ssh_password.txt

# Also update dashcamd config wifi section
cat > /mnt/data/config/wifi_override.conf << EOF
[wifi]
ssid = $SSID
password = $DEFAULT_WIFI_PASSWORD

[ssh]
password = $SSH_PASSWORD
EOF

echo "Configuration generation complete."