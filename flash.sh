#!/bin/bash
set -euo pipefail

#==============================================================================
# flash.sh — Flash dashcam firmware image to USB/SD card or HDC eMMC
#
# Usage:
#   sudo ./flash.sh /dev/sdX              — Flash and auto-resize data partition
#   sudo ./flash.sh /dev/sdX noresize      — Flash without resizing
#   sudo ./flash.sh /dev/sdX norestore     — Flash without backup-restore prompt
#
# SAFETY FEATURES:
#   1. Refuses to flash your system disk
#   2. Refuses to flash mounted devices
#   3. Requires typing 'YES' to confirm
#   4. Detects if target looks like an HDC eMMC (small size, RPi partition layout)
#      and offers to BACK UP the original firmware before overwriting
#   5. Backups are saved with timestamp and device info for easy identification
#==============================================================================

TARGET="${1:-}"
RESIZE="${2:-yes}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE="${SCRIPT_DIR}/output/images/sdcard.img"
BACKUP_DIR="${SCRIPT_DIR}/backups"

# Must be root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (sudo)"
    echo "  sudo $0 $@"
    exit 1
fi

# --- RESTORE MODE ---
# Usage: sudo ./flash.sh restore <backup.img> /dev/sdX
# This restores a previously backed-up firmware image to a device.
if [ "$TARGET" = "restore" ]; then
    BACKUP_FILE="${2:-}"
    RESTORE_TARGET="${3:-}"

    if [ -z "$BACKUP_FILE" ] || [ -z "$RESTORE_TARGET" ]; then
        echo "Usage: sudo $0 restore <backup.img> /dev/sdX"
        echo ""
        echo "Available backups:"
        if [ -d "$BACKUP_DIR" ]; then
            ls -lh "$BACKUP_DIR"/*.img 2>/dev/null || echo "  (no backups found)"
        else
            echo "  (no backup directory found)"
        fi
        exit 1
    fi

    if [ ! -f "$BACKUP_FILE" ]; then
        echo "ERROR: Backup file not found: ${BACKUP_FILE}"
        if [ -d "$BACKUP_DIR" ]; then
            echo ""
            echo "Available backups:"
            ls -lh "$BACKUP_DIR"/*.img 2>/dev/null
        fi
        exit 1
    fi

    if [ ! -b "$RESTORE_TARGET" ]; then
        echo "ERROR: ${RESTORE_TARGET} is not a block device"
        exit 1
    fi

    # Safety: refuse to write to system disk
    ROOT_DISK=$(findmnt -no SOURCE / | sed 's/[0-9]*$//' | sed 's/p$//')
    if [ "$RESTORE_TARGET" = "$ROOT_DISK" ] || [[ "$RESTORE_TARGET" == "${ROOT_DISK}"* ]]; then
        echo "ERROR: ${RESTORE_TARGET} appears to be your system disk. Refusing."
        exit 1
    fi

    # Safety: unmount if needed
    if lsblk "$RESTORE_TARGET" -o MOUNTPOINT -n | grep -qw .; then
        echo ">>> Unmounting ${RESTORE_TARGET}..."
        for part in "${RESTORE_TARGET}"*; do
            umount "$part" 2>/dev/null || true
        done
    fi

    BACKUP_SIZE=$(stat --format="%s" "$BACKUP_FILE")
    BACKUP_SIZE_GB=$((BACKUP_SIZE / 1000000000))

    echo "========================================"
    echo " FIRMWARE RESTORE TOOL"
    echo "========================================"
    echo " Backup:  ${BACKUP_FILE}"
    echo " Size:    ${BACKUP_SIZE_GB} GB"
    echo " Target:  ${RESTORE_TARGET}"
    echo "========================================"
    echo ""
    echo "WARNING: This will OVERWRITE everything on ${RESTORE_TARGET}"
    echo "         with the backed-up firmware image."
    echo ""
    read -p "Type 'RESTORE' to confirm: " CONFIRM
    if [ "$CONFIRM" != "RESTORE" ]; then
        echo "Aborted."
        exit 0
    fi

    echo ">>> Restoring firmware to ${RESTORE_TARGET}..."
    dd if="$BACKUP_FILE" of="$RESTORE_TARGET" bs=4M status=progress conv=fsync
    sync

    echo ""
    echo "========================================"
    echo " RESTORE COMPLETE"
    echo "========================================"
    echo " The original firmware has been restored."
    echo "========================================"
    exit 0
fi

# --- LIST BACKUPS MODE ---
if [ "$TARGET" = "backups" ]; then
    echo "Available firmware backups:"
    echo ""
    if [ -d "$BACKUP_DIR" ]; then
        ls -lht "$BACKUP_DIR"/*.img 2>/dev/null || echo "  (no backups found)"
        echo ""
        echo "Metadata files:"
        ls -lht "$BACKUP_DIR"/*.txt 2>/dev/null || echo "  (no metadata files)"
    else
        echo "  No backup directory found at ${BACKUP_DIR}"
    fi
    echo ""
    echo "To restore a backup:"
    echo "  sudo $0 restore <backup.img> /dev/sdX"
    exit 0
fi

# Must specify target
if [ -z "$TARGET" ]; then
    echo "Usage:"
    echo "  sudo $0 /dev/sdX [noresize]      — Flash firmware to device"
    echo "  sudo $0 restore <img> /dev/sdX   — Restore a backup image"
    echo "  sudo $0 backups                   — List available backups"
    echo ""
    echo "Available block devices:"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,MODEL 2>/dev/null | grep -E 'disk|part'
    exit 1
fi

# Verify image exists
if [ ! -f "$IMAGE" ]; then
    echo "ERROR: Firmware image not found at ${IMAGE}"
    echo "Run ./docker-build.sh first to build the firmware."
    exit 1
fi

# Verify target is a block device
if [ ! -b "$TARGET" ]; then
    echo "ERROR: ${TARGET} is not a block device"
    exit 1
fi

# Safety: refuse to flash the system disk
ROOT_DISK=$(findmnt -no SOURCE / | sed 's/[0-9]*$//' | sed 's/p$//')
if [ "$TARGET" = "$ROOT_DISK" ] || [ "$TARGET" = "${ROOT_DISK}p1" ] || [[ "$TARGET" == "${ROOT_DISK}"* ]]; then
    echo "ERROR: ${TARGET} appears to be your system disk. Refusing to flash."
    echo "System disk: ${ROOT_DISK}"
    exit 1
fi

# Safety: refuse if target is mounted
if lsblk "$TARGET" -o MOUNTPOINT -n | grep -qw .; then
    echo "ERROR: ${TARGET} or its partitions are currently mounted."
    echo "Unmount first: sudo umount ${TARGET}*"
    exit 1
fi

# Gather target info
IMG_SIZE=$(stat --format="%s" "$IMAGE")
IMG_SIZE_MB=$((IMG_SIZE / 1048576))
TARGET_SIZE=$(lsblk "$TARGET" -b -o SIZE -n | head -1)
TARGET_SIZE_GB=$((TARGET_SIZE / 1000000000))
TARGET_MODEL=$(lsblk "$TARGET" -o MODEL -n | head -1)
TARGET_TRAN=$(lsblk "$TARGET" -o TRAN -n | head -1)

# Detect if this looks like an HDC eMMC (likely connected via rpiboot/USB)
# HDC eMMC sizes are typically 8, 16, or 32 GB
IS_EMMC=false
if [[ "$TARGET_TRAN" == "usb" ]] && [[ "$TARGET_SIZE_GB" -le 64 ]]; then
    # Check if it has a partition layout that looks like RPi/Hivemapper
    PART_TABLE=$(parted -s "$TARGET" print 2>/dev/null || true)
    if echo "$PART_TABLE" | grep -qiE 'squashfs|boot\.vfat|rootfs|rauc|dashcam|hivemapper'; then
        IS_EMMC=true
    fi
    # Also check by partition count — HDC has 5+ partitions
    PART_COUNT=$(parted -s "$TARGET" print 2>/dev/null | grep -cE '^[ 0-9]' || echo 0)
    if [[ "$PART_COUNT" -ge 4 ]]; then
        IS_EMMC=true
    fi
fi

# Also detect mmcblk devices (direct eMMC on some boards)
if [[ "$TARGET" == *"mmcblk"* ]]; then
    IS_EMMC=true
fi

echo "========================================"
echo " FIRMWARE FLASH TOOL"
echo "========================================"
echo " Image:        ${IMAGE}"
echo " Image size:   ${IMG_SIZE_MB} MB"
echo " Target:       ${TARGET}"
echo " Target size:  ${TARGET_SIZE_GB} GB"
echo " Target model: ${TARGET_MODEL:-unknown}"
echo " Transport:    ${TARGET_TRAN:-unknown}"
echo " Resize:       ${RESIZE}"
echo "========================================"
echo ""

# --- BACKUP SECTION ---
# If this looks like an eMMC with existing firmware, offer to back it up
# before we overwrite it. This lets the user restore the original Hivemapper
# firmware if they ever want to go back.

BACKUP_FILE=""
if [ "$IS_EMMC" = true ]; then
    echo "WARNING: ${TARGET} appears to be an eMMC module with existing firmware."
    echo "Flashing will PERMANENTLY OVERWRITE whatever is currently on this device."
    echo ""
    echo "It is strongly recommended to BACK UP the current firmware first."
    echo "The backup will be a full disk image that can be restored with this same script."
    echo ""
    read -p "Back up current firmware before flashing? [Y/n] " DO_BACKUP
    DO_BACKUP="${DO_BACKUP:-Y}"

    if [[ "$DO_BACKUP" =~ ^[Yy]$ ]]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mkdir -p "$BACKUP_DIR"
        BACKUP_FILE="${BACKUP_DIR}/firmware_backup_${TIMESTAMP}.img"

        echo ""
        echo ">>> Backing up ${TARGET} to ${BACKUP_FILE}..."
        echo "    This reads the entire device and may take several minutes."
        echo "    Backup size will be ${TARGET_SIZE_GB} GB (full device dump)."
        echo ""

        # Use dd to read the entire device into a backup file
        # Use pv if available for progress, otherwise dd status=progress
        if command -v pv &>/dev/null; then
            pv "$TARGET" > "$BACKUP_FILE"
        else
            dd if="$TARGET" of="$BACKUP_FILE" bs=4M status=progress conv=fsync
        fi
        sync

        BACKUP_SIZE=$(stat --format="%s" "$BACKUP_FILE")
        BACKUP_SIZE_GB=$((BACKUP_SIZE / 1000000000))

        # Verify backup matches device size
        if [[ "$BACKUP_SIZE" -ne "$TARGET_SIZE" ]]; then
            echo "WARNING: Backup size (${BACKUP_SIZE} bytes) differs from device size (${TARGET_SIZE} bytes)"
            echo "The backup may be incomplete. Consider retrying."
        else
            echo ">>> Backup complete: ${BACKUP_FILE} (${BACKUP_SIZE_GB} GB)"
        fi

        # Create a metadata file alongside the backup
        META_FILE="${BACKUP_DIR}/firmware_backup_${TIMESTAMP}.txt"
        cat > "$META_FILE" << EOF
HDC Firmware Backup
===================
Backup date:    $(date)
Source device:  ${TARGET}
Device model:   ${TARGET_MODEL:-unknown}
Device size:    ${TARGET_SIZE} bytes (${TARGET_SIZE_GB} GB)
Transport:      ${TARGET_TRAN:-unknown}
Backup file:    ${BACKUP_FILE}
Backup size:    ${BACKUP_SIZE} bytes

This backup can be restored with:
  sudo dd if=${BACKUP_FILE} of=${TARGET} bs=4M status=progress
  sync

Or use the restore feature of flash.sh:
  sudo ./flash.sh restore ${BACKUP_FILE} ${TARGET}
EOF
        echo ">>> Metadata saved: ${META_FILE}"
        echo ""
        echo "To restore this backup later:"
        echo "  sudo ./flash.sh restore ${BACKUP_FILE} ${TARGET}"
        echo ""
    else
        echo ""
        echo "WARNING: Skipping backup. The original firmware on ${TARGET}"
        echo "will be permanently lost after flashing."
        echo ""
        read -p "Are you sure you want to continue WITHOUT backup? [y/N] " CONFIRM_NOBACKUP
        if [[ ! "$CONFIRM_NOBACKUP" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
    fi
else
    echo "WARNING: This will ERASE ALL DATA on ${TARGET}"
    echo ""
fi

# Final confirmation
echo ""
read -p "Type 'YES' to flash the firmware: " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
    echo "Aborted."
    exit 0
fi

# --- RESTORE PROMPT ---
# After flashing, if we made a backup, remind the user where it is
# and how to restore if needed.

# Unmount any partitions just in case
echo ">>> Unmounting target partitions..."
for part in "${TARGET}"*; do
    if [ -b "$part" ] && [ "$part" != "$TARGET" ]; then
        umount "$part" 2>/dev/null || true
    fi
done

# Flash the image
echo ">>> Flashing firmware image to ${TARGET}..."
dd if="$IMAGE" of="$TARGET" bs=4M status=progress conv=fsync
sync

echo ">>> Sync complete."

# Optionally resize the data partition to fill the remaining space
if [ "$RESIZE" = "yes" ]; then
    echo ">>> Resizing data partition to fill ${TARGET}..."

    # Re-read partition table after dd
    partprobe "$TARGET" 2>/dev/null || true
    sleep 2

    # Find the last partition (data partition)
    LAST_PART=$(lsblk "$TARGET" -o NAME -n | tail -1 | sed 's/[^0-9]*//')

    if [ -n "$LAST_PART" ]; then
        PART_DEV="${TARGET}${LAST_PART}"
        if [[ "$TARGET" == *"nvme"* ]] || [[ "$TARGET" == *"mmcblk"* ]]; then
            PART_DEV="${TARGET}p${LAST_PART}"
        fi

        echo ">>> Resizing partition ${LAST_PART}..."
        parted -s "$TARGET" resizepart "$LAST_PART" 100%
        partprobe "$TARGET" 2>/dev/null || true
        sleep 2

        echo ">>> Resizing filesystem on ${PART_DEV}..."
        e2fsck -f -y "$PART_DEV" || true
        resize2fs "$PART_DEV"
        sync
        echo ">>> Data partition resized."
    else
        echo "WARNING: Could not determine last partition. Manual resize needed."
    fi
fi

echo ""
echo "========================================"
echo " FLASH COMPLETE"
echo "========================================"
if [ -n "$BACKUP_FILE" ]; then
    echo ""
    echo " Original firmware backed up to:"
    echo "   ${BACKUP_FILE}"
    echo ""
    echo " To restore the original firmware later:"
    echo "   sudo ./flash.sh restore ${BACKUP_FILE} ${TARGET}"
fi
echo ""
echo " The USB/SD card is ready to boot."
echo ""
echo " To use in the HDC dashcam:"
echo ""
echo "   USB update method (recommended, no disassembly):"
echo "     1. Run: sudo ./usb-update.sh /dev/sdY"
echo "     2. Plug USB into powered-off HDC, power on, wait 2-3 min"
echo ""
echo "   SD card method:"
echo "     1. Insert the USB/SD card into the HDC"
echo "     2. Set CM4 to boot from SD/USB (jumper or config)"
echo "     3. Power on the HDC"
echo ""
echo "   Each device auto-generates a unique Wi-Fi SSID:"
echo "     SSID: hivehackerXXXX (last 4 of device serial)"
echo "     Password: hivehak!"
echo ""
echo "   Browse to: http://192.168.0.10"
echo "========================================"