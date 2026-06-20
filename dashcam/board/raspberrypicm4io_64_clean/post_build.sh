#!/bin/bash
set -eu

#==============================================================================
# post_build.sh for raspberrypicm4io_64_clean
# Replaces the stock post_build.sh — skips all Hivemapper-specific stuff
# (onnxruntime, opencv, tflite, camera-api) and handles only what we need.
#==============================================================================

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
BR2_EXTERNAL_DASHCAM_PATH="$(cd ${BOARD_DIR}/../.. && pwd)"

# --- Copy cmdline.txt for boot ---
install -D -m 0644 ${BR2_EXTERNAL_DASHCAM_PATH}/board/raspberrypi/cmdline.txt \
    ${BINARIES_DIR}/rpi-firmware/cmdline.txt

# --- Enable 64-bit boot in config.txt ---
CONFIG_PATH="${BINARIES_DIR}/rpi-firmware/config.txt"
if [ -f "$CONFIG_PATH" ]; then
    sed -i "s/#arm_64bit=1/arm_64bit=1/g" ${CONFIG_PATH}
fi

# --- Install RAUC keyring cert (needed for USB updates) ---
install -D -m 0644 ${BR2_EXTERNAL_DASHCAM_PATH}/board/raspberrypi/pki/dev/keyring/cert.pem \
    ${TARGET_DIR}/etc/rauc/keyring/cert.pem

# --- Generate SSH host keys (for dropbear/openssh) ---
if command -v ssh-keygen &>/dev/null; then
    ssh-keygen -A -f ${TARGET_DIR} 2>/dev/null || true
fi

# --- Enable our custom systemd services ---
mkdir -p "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants"

# Enable generate-ssid service (runs before hostapd to set unique SSID)
if [ -f "${TARGET_DIR}/etc/systemd/system/generate-ssid.service" ]; then
    ln -sf ../generate-ssid.service \
        "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/generate-ssid.service"
    echo "Enabled generate-ssid.service"
fi

# Enable dashcamd service
if [ -f "${TARGET_DIR}/usr/lib/systemd/system/dashcamd.service" ]; then
    ln -sf /usr/lib/systemd/system/dashcamd.service \
        "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/dashcamd.service"
    echo "Enabled dashcamd.service"
fi

# Enable dashcam-webui service
if [ -f "${TARGET_DIR}/usr/lib/systemd/system/dashcam-webui.service" ]; then
    ln -sf /usr/lib/systemd/system/dashcam-webui.service \
        "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/dashcam-webui.service"
    echo "Enabled dashcam-webui.service"
fi

# --- Disable stock Hivemapper services we don't need ---
for svc in wifiP2P wifiman bootbit sethostname txpower; do
    if [ -L "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/${svc}.service" ]; then
        rm "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/${svc}.service"
        echo "Disabled ${svc}.service"
    fi
done

# Keep these stock services enabled:
# - usb-update.service (how we flash via USB)
# - hostapd.service (Wi-Fi AP)
# - dnsmasq.service (DHCP/DNS)
# - expand-data.service (resizes data partition on first boot)

echo "Post-build customization complete."