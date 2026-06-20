#!/bin/sh
#
# generate-ssid.sh — Generate unique Wi-Fi SSID from device serial number
#
# Creates SSID: hivehackerXXXX (last 4 of CPU serial)
# Password: hivehak!
#
# This runs at boot before hostapd starts, rewriting /etc/hostapd.conf
# (or the overlay copy) with the device-specific SSID.
#

HOSTAPD_CONF="/etc/hostapd.conf"
DASHCAM_CONF="/mnt/data/config/dashcamd.conf"
DEFAULT_PASSWORD="hivehak!"

# Read the CPU serial number
# On BCM2711/CM4, this is available in /proc/cpuinfo or device tree
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

echo "Generated SSID: $SSID (from serial: $SERIAL)"

# Update hostapd.conf with the unique SSID and password
if [ -f "$HOSTAPD_CONF" ]; then
    # Check if this is a read-only rootfs (hostapd.conf is on overlay)
    # We can write to it since overlayfs makes it writable
    sed -i "s/^ssid=.*/ssid=$SSID/" "$HOSTAPD_CONF"
    sed -i "s/^wpa_passphrase=.*/wpa_passphrase=$DEFAULT_PASSWORD/" "$HOSTAPD_CONF"
    echo "Updated $HOSTAPD_CONF with SSID=$SSID"
else
    echo "WARNING: $HOSTAPD_CONF not found"
fi

# Also update dashcamd config so the web UI shows the correct SSID
if [ -d /mnt/data/config ]; then
    # Write a minimal override with just the wifi section
    cat > /mnt/data/config/wifi_override.conf << EOF
[wifi]
ssid = $SSID
password = $DEFAULT_PASSWORD
EOF
    echo "Updated wifi override config"
fi

# Write the generated SSID to a file for the web UI to read
echo "$SSID" > /mnt/data/config/generated_ssid.txt
echo "$DEFAULT_PASSWORD" > /mnt/data/config/generated_password.txt

echo "SSID generation complete."