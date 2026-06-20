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

# --- Disable stock Hivemapper services we don't need ---
for svc in wifiP2P wifiman bootbit sethostname txpower; do
    if [ -L "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/${svc}.service" ]; then
        rm "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/${svc}.service"
        echo "Disabled ${svc}.service"
    fi
done

echo "Post-build customization complete."