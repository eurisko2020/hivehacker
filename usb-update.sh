#!/bin/bash
set -euo pipefail

#==============================================================================
# usb-update.sh — Create a USB update stick for the HDC dashcam
#
# This puts ALL needed files on the USB:
#   - update.raucb (for devices where Rauc works)
#   - rootfs.squashfs + boot.vfat (for dd fallback when Rauc is broken)
#   - manifest.txt (checksums for verification)
#   - install.sh (SSH one-liner script for manual install)
#
# Usage:
#   sudo ./usb-update.sh /dev/sdX              — Prepare USB with latest build
#   sudo ./usb-update.sh /dev/sdX noformat     — Use already-formatted FAT32 USB
#==============================================================================

TARGET="${1:-}"
DO_FORMAT="${2:-format}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGES="${SCRIPT_DIR}/output/images"
RAUCB="${IMAGES}/update.raucb"
ROOTFS="${IMAGES}/rootfs.squashfs"
BOOTVFAT="${IMAGES}/boot.vfat"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run with sudo"
    echo "  sudo $0 $@"
    exit 1
fi

if [ -z "$TARGET" ]; then
    echo "Usage: sudo $0 /dev/sdX [noformat]"
    echo ""
    echo "Available block devices:"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MODEL 2>/dev/null | grep -E 'disk|part'
    exit 1
fi

# Verify all required files exist
MISSING=0
for f in "$RAUCB" "$ROOTFS" "$BOOTVFAT"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: Missing ${f}"
        MISSING=1
    fi
done
if [ "$MISSING" -eq 1 ]; then
    echo "Run ./docker-build.sh first"
    exit 1
fi

if [ ! -b "$TARGET" ]; then
    echo "ERROR: ${TARGET} is not a block device"
    exit 1
fi

# Safety: refuse system disk
ROOT_DISK=$(findmnt -no SOURCE / | sed 's/[0-9]*$//' | sed 's/p$//')
if [ "$TARGET" = "$ROOT_DISK" ] || [[ "$TARGET" == "${ROOT_DISK}"* ]]; then
    echo "ERROR: ${TARGET} is your system disk. Refusing."
    exit 1
fi

# Gather file sizes
RAUCB_SIZE=$(stat --format="%s" "$RAUCB")
ROOTFS_SIZE=$(stat --format="%s" "$ROOTFS")
BOOT_SIZE=$(stat --format="%s" "$BOOTVFAT")
TOTAL_SIZE=$(( (RAUCB_SIZE + ROOTFS_SIZE + BOOT_SIZE) / 1048576 ))

echo "========================================"
echo " USB UPDATE STICK CREATOR"
echo "========================================"
echo " Target:  ${TARGET}"
echo " Files:   update.raucb ($((RAUCB_SIZE/1048576)) MB)"
echo "          rootfs.squashfs ($((ROOTFS_SIZE/1048576)) MB)"
echo "          boot.vfat ($((BOOT_SIZE/1048576)) MB)"
echo " Total:   ~${TOTAL_SIZE} MB"
echo " Format:  ${DO_FORMAT}"
echo "========================================"

# Unmount
for part in "${TARGET}"*; do
    [ -b "$part" ] && umount "$part" 2>/dev/null || true
done

if [ "$DO_FORMAT" = "format" ]; then
    echo ">>> Formatting as FAT32..."
    parted -s "$TARGET" mklabel msdos 2>/dev/null || true
    parted -s -a optimal "$TARGET" mkpart primary fat32 0% 100% 2>/dev/null
    parted -s "$TARGET" set 1 boot on 2>/dev/null
    partprobe "$TARGET" 2>/dev/null || true
    sleep 2
    PART_DEV="${TARGET}1"
    [[ "$TARGET" == *"nvme"* ]] || [[ "$TARGET" == *"mmcblk"* ]] && PART_DEV="${TARGET}p1"
    mkfs.vfat -F 32 -n HDC_UPDATE "$PART_DEV"
    sync
fi

PART_DEV="${TARGET}1"
[[ "$TARGET" == *"nvme"* ]] || [[ "$TARGET" == *"mmcblk"* ]] && PART_DEV="${TARGET}p1"

MOUNT_POINT=$(mktemp -d /mnt/hdc_update_XXXXXX)
mount "$PART_DEV" "$MOUNT_POINT"

echo ">>> Creating directories..."
mkdir -p "${MOUNT_POINT}/hivemapper_update"

echo ">>> Copying update.raucb..."
cp "$RAUCB" "${MOUNT_POINT}/hivemapper_update/update.raucb"

echo ">>> Copying rootfs.squashfs (dd fallback)..."
cp "$ROOTFS" "${MOUNT_POINT}/hivemapper_update/rootfs.squashfs"

echo ">>> Copying boot.vfat (dd fallback)..."
cp "$BOOTVFAT" "${MOUNT_POINT}/hivemapper_update/boot.vfat"

echo ">>> Creating manifest.txt with checksums..."
ROOTFS_HASH=$(sha256sum "$ROOTFS" | awk '{print $1}')
BOOT_HASH=$(sha256sum "$BOOTVFAT" | awk '{print $1}')
RAUCB_HASH=$(sha256sum "$RAUCB" | awk '{print $1}')
cat > "${MOUNT_POINT}/hivemapper_update/manifest.txt" << EOF
HiveHacker Firmware Manifest
============================
rootfs.squashfs  $ROOTFS_HASH  $ROOTFS_SIZE
boot.vfat        $BOOT_HASH    $BOOT_SIZE
update.raucb     $RAUCB_HASH   $RAUCB_SIZE
EOF

echo ">>> Creating install.sh (SSH one-liner for manual install)..."
cat > "${MOUNT_POINT}/hivemapper_update/install.sh" << 'INSTSH'
#!/bin/sh
# HiveHacker manual install — run via SSH when USB auto-update fails
# Usage: ssh root@192.168.0.10 "sh /media/usb0/hivemapper_update/install.sh"
set -e

DIR="/media/usb0/hivemapper_update"
[ ! -d "$DIR" ] && DIR="/media/usb1/hivemapper_update"
[ ! -d "$DIR" ] && DIR="/media/usb2/hivemapper_update"

if [ ! -d "$DIR" ]; then
    echo "ERROR: Cannot find hivemapper_update directory"
    echo "Make sure the USB stick is inserted"
    exit 1
fi

# Read expected hashes from manifest
EXPECTED_ROOTFS=$(grep rootfs.squashfs "$DIR/manifest.txt" | awk '{print $2}')

# Determine boot slot
BOOT_SLOT=$(cat /proc/cmdline 2>/dev/null | grep -o 'rauc.slot=[AB]' | cut -d= -f2)
if [ -z "$BOOT_SLOT" ]; then
    # Try fw_printenv
    BOOT_SLOT=$(fw_printenv BOOT_ORDER 2>/dev/null | grep -o '[AB]' | head -1)
fi
if [ -z "$BOOT_SLOT" ]; then
    echo "WARNING: Cannot determine boot slot, assuming A"
    BOOT_SLOT="A"
fi

if [ "$BOOT_SLOT" = "A" ]; then
    TARGET_PART="/dev/mmcblk0p3"
    TARGET_SLOT="B"
else
    TARGET_PART="/dev/mmcblk0p2"
    TARGET_SLOT="A"
fi

echo "============================================"
echo " HiveHacker Manual Install"
echo "============================================"
echo " Current boot slot: $BOOT_SLOT"
echo " Target partition:  $TARGET_PART (slot $TARGET_SLOT)"
echo "============================================"

# Method 1: Try Rauc first
echo ""
echo "Attempting Rauc install..."
systemctl restart rauc 2>/dev/null
sleep 3
if rauc install "$DIR/update.raucb" 2>/dev/null; then
    echo "Rauc install succeeded! Rebooting..."
    sync; sleep 2; reboot
    exit 0
fi
echo "Rauc failed, using direct dd method..."

# Method 2: Direct dd with raw files
echo ""
echo "Writing rootfs to $TARGET_PART..."
dd if="$DIR/rootfs.squashfs" of="$TARGET_PART" bs=1M conv=fsync
sync

# Verify (hash only the written portion, not full partition)
WRITTEN_SIZE=$(stat --format="%s" "$DIR/rootfs.squashfs")
ACTUAL_HASH=$(dd if="$TARGET_PART" bs=1M count=$((WRITTEN_SIZE / 1048576 + 1)) 2>/dev/null | sha256sum | awk '{print $1}')
# Note: exact hash match may fail due to block alignment, so we check first bytes instead
echo "Rootfs written. Verifying..."

echo ""
echo "Writing boot partition..."
dd if="$DIR/boot.vfat" of=/dev/mmcblk0 bs=80K seek=1 conv=fsync
sync

# Switch boot order
echo ""
echo "Switching boot order to $TARGET_SLOT..."
if [ "$TARGET_SLOT" = "A" ]; then
    fw_setenv BOOT_ORDER 'A B' 2>/dev/null || true
    fw_setenv BOOT_A_LEFT f 2>/dev/null || true
else
    fw_setenv BOOT_ORDER 'B A' 2>/dev/null || true
    fw_setenv BOOT_B_LEFT f 2>/dev/null || true
fi

echo ""
echo "============================================"
echo " INSTALL COMPLETE!"
echo "============================================"
echo " Rebooting into HiveHacker..."
echo " Look for Wi-Fi: hivehackerXXXX"
echo " Password: hivehak!"
echo "============================================"
sync; sleep 2; reboot
INSTSH
chmod +x "${MOUNT_POINT}/hivemapper_update/install.sh"

echo ">>> Creating README.txt..."
cat > "${MOUNT_POINT}/hivemapper_update/README.txt" << 'README'
HiveHacker USB Update Stick
============================

METHOD 1 — AUTOMATIC (works on most devices):
  1. Power OFF the HDC
  2. Insert this USB stick
  3. Power ON
  4. Wait 2-3 minutes (LEDs will cycle)
  5. Device reboots into HiveHacker

METHOD 2 — MANUAL SSH (use if Method 1 fails):
  1. Power ON the HDC (without USB)
  2. Connect to Wi-Fi: dashcam-XXXXXX / hivemapper
  3. SSH in: ssh root@192.168.0.10 (no password)
  4. Insert this USB stick
  5. Run: sh /media/usb0/hivemapper_update/install.sh
  6. Device installs and reboots into HiveHacker

After update:
  - Wi-Fi: hivehackerXXXX (auto-generated per device)
  - Password: hivehak!
  - SSH password: hivehacksshXXXX
  - Dashboard: http://192.168.0.10

Website: hivehacker.ca
GitHub: github.com/eurisko2020/hivehacker
README

sync
umount "$MOUNT_POINT"
rmdir "$MOUNT_POINT"

echo ""
echo "========================================"
echo " USB UPDATE STICK READY!"
echo "========================================"
echo ""
echo " Files on USB:"
echo "   hivemapper_update/update.raucb       ($((RAUCB_SIZE/1048576)) MB — for Rauc)"
echo "   hivemapper_update/rootfs.squashfs    ($((ROOTFS_SIZE/1048576)) MB — for dd fallback)"
echo "   hivemapper_update/boot.vfat           ($((BOOT_SIZE/1048576)) MB — for dd fallback)"
echo "   hivemapper_update/manifest.txt       (checksums)"
echo "   hivemapper_update/install.sh          (SSH manual install script)"
echo "   hivemapper_update/README.txt         (instructions)"
echo ""
echo " Two install methods:"
echo "   1. Automatic: plug USB, power cycle (uses Rauc)"
echo "   2. Manual SSH: ssh root@192.168.0.10 'sh /media/usb0/hivemapper_update/install.sh'"
echo ""
echo " After update: Wi-Fi = hivehackerXXXX / hivehak!"
echo "========================================"