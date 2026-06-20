#!/bin/bash
set -euo pipefail

#==============================================================================
# usb-update.sh — Create a USB update stick for the HDC dashcam
#
# Usage:
#   sudo ./usb-update.sh /dev/sdX              — Prepare USB stick with latest build
#   sudo ./usb-update.sh /dev/sdX noformat     — Use already-formatted FAT32 USB
#
# This creates a FAT32 USB stick with the hivemapper_update/ directory containing
# the update.raucb bundle. You plug it into the powered-off HDC, then power on.
# The device auto-detects the update, installs it to the inactive A/B partition,
# and reboots into the new firmware.
#
# No disassembly, no rpiboot, no button needed.
# The old firmware stays on the other A/B partition as a fallback.
#
# Requirements:
#   - The USB stick must be FAT32 formatted (this script can do it)
#   - The build must have produced output/images/update.raucb
#==============================================================================

TARGET="${1:-}"
DO_FORMAT="${2:-format}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RAUCB="${SCRIPT_DIR}/output/images/update.raucb"

# Must be root for formatting and mounting
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (sudo)"
    echo "  sudo $0 $@"
    exit 1
fi

if [ -z "$TARGET" ]; then
    echo "Usage: sudo $0 /dev/sdX [noformat]"
    echo ""
    echo "Creates a USB update stick for the HDC dashcam."
    echo "The USB must be FAT32. This script will format it unless you pass 'noformat'."
    echo ""
    echo "Available block devices:"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,MODEL 2>/dev/null | grep -E 'disk|part'
    exit 1
fi

# Verify raucb exists
if [ ! -f "$RAUCB" ]; then
    echo "ERROR: Update bundle not found at ${RAUCB}"
    echo ""
    echo "Run the build first:"
    echo "  ./docker-build.sh"
    echo ""
    echo "The build produces update.raucb alongside sdcard.img"
    exit 1
fi

# Verify target is a block device
if [ ! -b "$TARGET" ]; then
    echo "ERROR: ${TARGET} is not a block device"
    exit 1
fi

# Safety: refuse to touch system disk
ROOT_DISK=$(findmnt -no SOURCE / | sed 's/[0-9]*$//' | sed 's/p$//')
if [ "$TARGET" = "$ROOT_DISK" ] || [[ "$TARGET" == "${ROOT_DISK}"* ]]; then
    echo "ERROR: ${TARGET} appears to be your system disk. Refusing."
    exit 1
fi

RAUCB_SIZE=$(stat --format="%s" "$RAUCB")
RAUCB_SIZE_MB=$((RAUCB_SIZE / 1048576))

echo "========================================"
echo " USB UPDATE STICK CREATOR"
echo "========================================"
echo " Bundle:  ${RAUCB}"
echo " Size:    ${RAUCB_SIZE_MB} MB"
echo " Target:  ${TARGET}"
echo " Format:  ${DO_FORMAT}"
echo "========================================"
echo ""

# Unmount any existing partitions
echo ">>> Unmounting ${TARGET}..."
for part in "${TARGET}"*; do
    if [ -b "$part" ]; then
        umount "$part" 2>/dev/null || true
    fi
done

if [ "$DO_FORMAT" = "format" ]; then
    echo ">>> Formatting ${TARGET} as FAT32..."

    # Create a single FAT32 partition
    parted -s "$TARGET" mklabel msdos 2>/dev/null || true
    parted -s "$TARGET" mkpart primary fat32 0% 100% 2>/dev/null || true
    parted -s "$TARGET" set 1 boot on 2>/dev/null || true
    partprobe "$TARGET" 2>/dev/null || true
    sleep 2

    # Determine partition device name
    PART_DEV="${TARGET}1"
    if [[ "$TARGET" == *"nvme"* ]] || [[ "$TARGET" == *"mmcblk"* ]]; then
        PART_DEV="${TARGET}p1"
    fi

    # Format as FAT32
    mkfs.vfat -F 32 -n HDC_UPDATE "$PART_DEV"
    sync
    echo ">>> FAT32 format complete."
else
    # Use existing partition
    PART_DEV="${TARGET}1"
    if [[ "$TARGET" == *"nvme"* ]] || [[ "$TARGET" == *"mmcblk"* ]]; then
        PART_DEV="${TARGET}p1"
    fi

    # Verify it's actually FAT32
    FSTYPE=$(lsblk "$PART_DEV" -o FSTYPE -n 2>/dev/null || echo "")
    if [ "$FSTYPE" != "vfat" ] && [ "$FSTYPE" != "fat32" ]; then
        echo "WARNING: ${PART_DEV} is not FAT32 (detected: ${FSTYPE:-none})"
        echo "The HDC USB update script requires FAT32."
        read -p "Continue anyway? [y/N] " CONT
        if [[ ! "$CONT" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
    fi
fi

# Mount the USB stick
MOUNT_POINT=$(mktemp -d /mnt/hdc_update_XXXXXX)
echo ">>> Mounting ${PART_DEV} at ${MOUNT_POINT}..."
mount "$PART_DEV" "$MOUNT_POINT"

# Create the update directory
echo ">>> Creating hivemapper_update/ directory..."
mkdir -p "${MOUNT_POINT}/hivemapper_update"

# Copy the raucb bundle
echo ">>> Copying update bundle (${RAUCB_SIZE_MB} MB)..."
cp "$RAUCB" "${MOUNT_POINT}/hivemapper_update/update.raucb"
sync

# Verify the copy
COPIED_SIZE=$(stat --format="%s" "${MOUNT_POINT}/hivemapper_update/update.raucb")
if [ "$COPIED_SIZE" -ne "$RAUCB_SIZE" ]; then
    echo "ERROR: Copy verification failed! Sizes don't match."
    echo "  Original: ${RAUCB_SIZE} bytes"
    echo "  Copied:   ${COPIED_SIZE} bytes"
    umount "$MOUNT_POINT"
    rmdir "$MOUNT_POINT"
    exit 1
fi

# Unmount
echo ">>> Unmounting..."
umount "$MOUNT_POINT"
rmdir "$MOUNT_POINT"

echo ""
echo "========================================"
echo " USB UPDATE STICK READY"
echo "========================================"
echo ""
echo " To install the firmware on the HDC:"
echo ""
echo "   1. Power OFF the HDC dashcam"
echo "   2. Insert this USB stick into the HDC's USB port"
echo "   3. Power ON the HDC"
echo "   4. Wait 2-3 minutes (LEDs will turn off then back on)"
echo "   5. The HDC reboots into the new firmware automatically"
echo ""
echo " The old firmware stays on the other A/B partition as fallback."
echo " If the new firmware fails to boot, the device automatically"
echo " falls back to the previous firmware after 10 failed boot attempts."
echo ""
echo " After the update, each device auto-generates a unique Wi-Fi SSID:"
echo "   SSID: hivehackerXXXX (last 4 of device serial)"
echo "   Password: hivehak!"
echo ""
echo " Browse to http://192.168.0.10"
echo "========================================"