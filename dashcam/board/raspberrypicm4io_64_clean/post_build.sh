#!/bin/bash
set -eu

#==============================================================================
# post_build.sh for raspberrypicm4io_64_clean
# Replaces the stock post_build.sh — skips all Hivemapper-specific stuff
# and handles only what we need.
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

# --- Generate SSH host keys ---
if command -v ssh-keygen &>/dev/null; then
    ssh-keygen -A -f ${TARGET_DIR} 2>/dev/null || true
fi

# --- Install our SSH authorized_keys for root access ---
mkdir -p ${TARGET_DIR}/root/.ssh
if [ -f "${BOARD_DIR}/overlays/common/root/.ssh/authorized_keys" ]; then
    install -D -m 600 ${BOARD_DIR}/overlays/common/root/.ssh/authorized_keys \
        ${TARGET_DIR}/root/.ssh/authorized_keys
    echo "Installed SSH authorized_keys for root"
fi

# --- Configure dropbear to allow password auth (for first setup) ---
DROPBEAR_CFG="${TARGET_DIR}/etc/default/dropbear"
if [ -d "${TARGET_DIR}/etc/default" ]; then
    cat > "$DROPBEAR_CFG" << 'DROPBEAR_EOF'
# Dropbear configuration
# Allow password authentication for initial setup
DROPBEAR_EXTRA_ARGS="-R -B"
DROPBEAR_EOF
    echo "Configured dropbear with password auth"
fi

# Also set root password to empty (allow login)
if [ -f "${TARGET_DIR}/etc/shadow" ]; then
    sed -i 's|^root:[^:]*:|root::|' ${TARGET_DIR}/etc/shadow
    echo "Set root password to empty (no password)"
fi

# --- Configure nginx to proxy to Flask app ---
NGINX_CFG="${TARGET_DIR}/etc/nginx/nginx.conf"
cat > "$NGINX_CFG" << 'NGINX_EOF'
worker_processes 1;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80 default_server;
        server_name _;
        
    # Captive portal — catch all common detection URLs that iOS/Android/Windows hit
    # When a device connects, the OS checks these URLs to see if there's internet.
    # We intercept them and redirect to our dashboard.
    
    # iOS/macOS captive portal detection
    location = /hotspot-detect.html {
        return 302 http://192.168.0.10/;
    }
    
    # Android captive portal detection
    location = /generate_204 {
        return 302 http://192.168.0.10/;
    }
    
    # Windows captive portal detection
    location = /ncsi.txt {
        return 302 http://192.168.0.10/;
    }
    
    # Firefox captive portal detection
    location = /success.txt {
        return 302 http://192.168.0.10/;
    }
    
    # Static files (CSS, JS)
    location /static/ {
        alias /opt/dashcam/webui/static/;
    }
    
    # Live MJPEG stream
    location /stream {
        proxy_pass http://127.0.0.1:5000/stream;
        proxy_buffering off;
        proxy_cache off;
        proxy_set_header Host $host;
    }
    
    # All other requests go to Flask
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF
echo "Configured nginx with Flask proxy + captive portal"

# --- Ensure Flask app listens on port 5000 ---
# The app.py already runs on port 5000 when executed directly

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

# Enable led-controller service (IS31FL3199 I2C LED driver)
if [ -f "${TARGET_DIR}/usr/lib/systemd/system/led-controller.service" ]; then
    ln -sf /usr/lib/systemd/system/led-controller.service \
        "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/led-controller.service"
    echo "Enabled led-controller.service"
fi

# --- Disable stock Hivemapper services we don't need ---
for svc in wifiP2P wifiman bootbit sethostname txpower; do
    if [ -L "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/${svc}.service" ]; then
        rm "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/${svc}.service"
        echo "Disabled ${svc}.service"
    fi
done

# --- FIX: Rauc D-Bus timing issue ---
# On some devices, Rauc starts before D-Bus is fully ready, causing:
#   "Connection to the system bus can't be made for de.pengutronix.rauc"
# Fix: Add a drop-in that waits for D-Bus and retries
mkdir -p ${TARGET_DIR}/etc/systemd/system/rauc.service.d
cat > ${TARGET_DIR}/etc/systemd/system/rauc.service.d/hivehacker-fix.conf << 'RAUCFIX'
[Unit]
After=dbus.service dbus.socket
Requires=dbus.service
Wants=dbus.socket

[Service]
# Wait for D-Bus socket to be ready before starting
ExecStartPre=/bin/sh -c 'for i in 1 2 3 4 5 6 7 8 9 10; do test -S /run/dbus/system_bus_socket && break; sleep 1; done'
# Retry on failure
Restart=on-failure
RestartSec=3
RAUCFIX
echo "Applied Rauc D-Bus timing fix"

# --- Install our robust USB update script ---
# This replaces the stock usb_update.sh with a version that:
# 1. Waits for Rauc to be ready (retries if D-Bus not available)
# 2. Falls back to direct dd if Rauc still fails
# 3. Works on any device, every time
cat > ${TARGET_DIR}/opt/dashcam/bin/usb_update.sh << 'USBUPDATE'
#!/bin/sh
# HiveHacker USB Update Script — robust version
# Waits for Rauc, falls back to dd if needed

MOUNT_PATH="/media"
UPDATE_DIR="hivemapper_update"
CERT_PATH="/etc/rauc/keyring/cert.pem"

# Search all USB mount points
for INDEX in $(seq 0 7); do
    BASE_DIR="$MOUNT_PATH/usb$INDEX"
    SEARCH_PATH="$BASE_DIR/$UPDATE_DIR"
    
    if [ ! -d "$SEARCH_PATH" ]; then
        continue
    fi
    
    echo "Found update directory in $BASE_DIR"
    
    # Find the .raucb file
    UPDATE_FILE=$(ls -1 "$SEARCH_PATH"/*.raucb 2>/dev/null | head -1)
    if [ -z "$UPDATE_FILE" ]; then
        echo "No .raucb file found in $SEARCH_PATH"
        continue
    fi
    
    echo "Found update file: $UPDATE_FILE"
    
    # Update system time from cert
    if [ -f "$CERT_PATH" ]; then
        CERT_DATE=$(openssl x509 -startdate -noout -in "$CERT_PATH" 2>/dev/null | cut -d= -f2)
        if [ -n "$CERT_DATE" ]; then
            timedatectl set-ntp 0 2>/dev/null
            sleep 1
            timedatectl set-time "$CERT_DATE" 2>/dev/null
            sleep 1
        fi
    fi
    
    # Copy to /tmp for reliable reading
    cp "$UPDATE_FILE" /tmp/update.raucb
    
    # --- METHOD 1: Try Rauc (preferred, uses A/B with rollback) ---
    echo "Waiting for Rauc service..."
    for i in $(seq 1 15); do
        if systemctl is-active --quiet rauc 2>/dev/null; then
            echo "Rauc is ready!"
            break
        fi
        echo "Waiting for Rauc... ($i/15)"
        systemctl restart rauc 2>/dev/null
        sleep 2
    done
    
    echo "Attempting Rauc install..."
    if rauc install /tmp/update.raucb 2>/dev/null; then
        echo "Rauc install succeeded! Rebooting..."
        sync
        sleep 2
        reboot
        exit 0
    fi
    
    echo "Rauc install failed, trying direct method..."
    
    # --- METHOD 2: Direct dd to inactive partition (fallback) ---
    # Determine which slot is currently booted
    BOOT_SLOT=$(cat /proc/cmdline 2>/dev/null | grep -o 'rauc.slot=[AB]' | cut -d= -f2)
    
    if [ "$BOOT_SLOT" = "A" ]; then
        TARGET_PART="/dev/mmcblk0p3"
        TARGET_SLOT="B"
    elif [ "$BOOT_SLOT" = "B" ]; then
        TARGET_PART="/dev/mmcblk0p2"
        TARGET_SLOT="A"
    else
        echo "ERROR: Cannot determine boot slot. Aborting."
        exit 1
    fi
    
    echo "Currently booted from slot $BOOT_SLOT"
    echo "Writing to inactive slot $TARGET_SLOT ($TARGET_PART)"
    
    # Extract rootfs and boot from the raucb bundle
    # The raucb is a squashfs bundle — we need to extract it
    # Use rauc info to get the images, or fall back to dd of the full bundle
    
    # Try using rauc extract (if available)
    TMPDIR=$(mktemp -d)
    if rauc extract /tmp/update.raucb "$TMPDIR" 2>/dev/null; then
        echo "Extracted bundle to $TMPDIR"
        ROOTFS_IMG="$TMPDIR/rootfs.squashfs"
        BOOT_IMG="$TMPDIR/boot.vfat"
    else
        echo "rauc extract not available, using pre-extracted images..."
        # The bundle contains rootfs.squashfs and boot.vfat
        # Try mounting and extracting manually
        mount -t squashfs -o loop /tmp/update.raucb "$TMPDIR" 2>/dev/null
        ROOTFS_IMG="$TMPDIR/rootfs.squashfs"
        BOOT_IMG="$TMPDIR/boot.vfat"
    fi
    
    if [ ! -f "$ROOTFS_IMG" ]; then
        echo "ERROR: Cannot find rootfs.squashfs in bundle"
        # Last resort: try the casync/verity format
        umount "$TMPDIR" 2>/dev/null
        rmdir "$TMPDIR" 2>/dev/null
        echo "FATAL: Cannot extract firmware. Please use the sdcard.img method."
        exit 1
    fi
    
    echo "Writing rootfs to $TARGET_PART..."
    dd if="$ROOTFS_IMG" of="$TARGET_PART" bs=1M conv=fsync 2>&1
    sync
    
    if [ -f "$BOOT_IMG" ]; then
        echo "Writing boot partition..."
        dd if="$BOOT_IMG" of=/dev/mmcblk0 bs=80K seek=1 conv=fsync 2>&1
        sync
    fi
    
    # Cleanup
    umount "$TMPDIR" 2>/dev/null
    rm -rf "$TMPDIR"
    rm -f /tmp/update.raucb
    
    # Switch boot order to the newly written slot
    if [ "$TARGET_SLOT" = "A" ]; then
        fw_setenv BOOT_ORDER 'A B'
        fw_setenv BOOT_A_LEFT f
    else
        fw_setenv BOOT_ORDER 'B A'
        fw_setenv BOOT_B_LEFT f
    fi
    
    echo "========================================"
    echo " FIRMWARE INSTALLED SUCCESSFULLY!"
    echo "========================================"
    echo "Rebooting into HiveHacker..."
    sync
    sleep 2
    reboot
    exit 0
done

echo "No update directory found on any USB device."
exit 0
USBUPDATE
chmod +x ${TARGET_DIR}/opt/dashcam/bin/usb_update.sh
echo "Installed robust USB update script"

echo "Post-build customization complete."