#!/bin/bash
set -euo pipefail

#==============================================================================
# build.sh — Reusable firmware build script for HDC Clean Dashcam
#
# Usage:
#   ./build.sh              — Build stock firmware (verify toolchain)
#   ./build.sh clean        — Full clean build
#   ./build.sh custom       — Build our custom clean dashcam image
#   ./build.sh stock        — Build stock Hivemapper image (for reference)
#
# This script runs inside the Docker container (hdc-firmware-builder)
# OR directly on Ubuntu 20.04. It does NOT work on Ubuntu 26.04 due to
# GCC 15 incompatibility with the old Buildroot tree.
#==============================================================================

MODE="${1:-stock}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="${SCRIPT_DIR}"
OUTPUT_DIR="${REPO_DIR}/output"
CCACHE_DIR="${REPO_DIR}/.buildroot-ccache"

echo "========================================"
echo " HDC Clean Dashcam Firmware Builder"
echo " Mode: ${MODE}"
echo " Repo: ${REPO_DIR}"
echo "========================================"

# Clean if requested
if [ "${MODE}" = "clean" ]; then
    echo ">>> Cleaning output and ccache..."
    rm -rf "${OUTPUT_DIR}" "${CCACHE_DIR}"
    MODE="custom"
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Select defconfig
case "${MODE}" in
    stock)
        DEFCONFIG="raspberrypicm4io_64_dev_dashcam_defconfig"
        ;;
    custom)
        DEFCONFIG="raspberrypicm4io_64_clean_dashcam_defconfig"
        ;;
    *)
        echo "Unknown mode: ${MODE}"
        echo "Usage: $0 [stock|custom|clean]"
        exit 1
        ;;
esac

echo ">>> Using defconfig: ${DEFCONFIG}"

# Step 1: Load defconfig
echo ">>> Step 1: Loading defconfig..."
make -C "${REPO_DIR}/buildroot" \
    BR2_EXTERNAL="${REPO_DIR}/dashcam" \
    O="${OUTPUT_DIR}" \
    "${DEFCONFIG}"

# Step 2: Build
echo ">>> Step 2: Building firmware (this takes 30-60 minutes)..."
cd "${OUTPUT_DIR}"
make -j"$(nproc)"

# Step 3: Verify output
echo ">>> Step 3: Verifying output..."
if [ -f "${OUTPUT_DIR}/images/sdcard.img" ]; then
    IMG_SIZE=$(stat --format="%s" "${OUTPUT_DIR}/images/sdcard.img")
    IMG_SIZE_MB=$((IMG_SIZE / 1048576))
    echo ""
    echo "========================================"
    echo " BUILD SUCCESSFUL"
    echo "========================================"
    echo " Image: ${OUTPUT_DIR}/images/sdcard.img"
    echo " Size:  ${IMG_SIZE_MB} MB"
    echo ""
    echo " To flash to USB/SD card:"
    echo "   sudo dd if=${OUTPUT_DIR}/images/sdcard.img of=/dev/sdX bs=4M status=progress"
    echo "   sync"
    echo ""
    echo " Or use the flash script:"
    echo "   sudo ./flash.sh /dev/sdX"
    echo "========================================"
else
    echo "========================================"
    echo " BUILD FAILED — sdcard.img not found"
    echo " Check build logs in ${OUTPUT_DIR}/"
    echo "========================================"
    exit 1
fi