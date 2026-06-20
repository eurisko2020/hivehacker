#!/bin/bash
set -euo pipefail

#==============================================================================
# docker-build.sh — Build the dashcam firmware using Docker
#
# This is the main entry point for building the firmware on any Linux host
# (Ubuntu 20.04, 22.04, 24.04, 26.04, Debian, etc.)
# It uses a Docker container with Ubuntu 20.04 pinned for Buildroot compat.
#
# Usage:
#   ./docker-build.sh              — Build custom clean dashcam firmware
#   ./docker-build.sh stock        — Build stock Hivemapper firmware (reference)
#   ./docker-build.sh clean        — Full clean + custom build
#   ./docker-build.sh shell        — Open a shell in the build container
#
# The output image (sdcard.img) is written to ./output/images/sdcard.img
# Flash it with: sudo ./flash.sh /dev/sdX
#==============================================================================

MODE="${1:-custom}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_NAME="hdc-firmware-builder"
CONTAINER_OUTPUT="/dashcam/output"
HOST_OUTPUT="${SCRIPT_DIR}/output"
HOST_CCACHE="${SCRIPT_DIR}/.buildroot-ccache"

echo "========================================"
echo " HDC Dashcam Docker Build Pipeline"
echo " Mode: ${MODE}"
echo "========================================"

# Step 1: Build Docker image (if not exists or needs rebuild)
echo ">>> Step 1: Ensuring Docker build image exists..."
docker build -t "${IMAGE_NAME}" -f "${SCRIPT_DIR}/Dockerfile.build" "${SCRIPT_DIR}" 2>&1 | tail -5
echo ">>> Docker image ready: ${IMAGE_NAME}"

# Step 2: Run the build inside the container
echo ">>> Step 2: Running build in Docker container..."

case "${MODE}" in
    shell)
        echo ">>> Opening shell in build container..."
        docker run --rm -it \
            -v "${SCRIPT_DIR}:/dashcam" \
            -v "${HOST_CCACHE}:/dashcam/.buildroot-ccache" \
            -w /dashcam \
            "${IMAGE_NAME}" \
            /bin/bash
        ;;
    clean)
        echo ">>> Cleaning previous build artifacts..."
        rm -rf "${HOST_OUTPUT}" "${HOST_CCACHE}"
        docker run --rm \
            -v "${SCRIPT_DIR}:/dashcam" \
            -v "${HOST_CCACHE}:/dashcam/.buildroot-ccache" \
            -w /dashcam \
            "${IMAGE_NAME}" \
            bash -c 'mkdir -p output && make -C buildroot/ BR2_EXTERNAL=../dashcam O=../output raspberrypicm4io_64_clean_dashcam_defconfig && cd output && make -j$(nproc)' 2>&1 | tail -50
        ;;
    stock)
        docker run --rm \
            -v "${SCRIPT_DIR}:/dashcam" \
            -v "${HOST_CCACHE}:/dashcam/.buildroot-ccache" \
            -w /dashcam \
            "${IMAGE_NAME}" \
            bash -c 'mkdir -p output && make -C buildroot/ BR2_EXTERNAL=../dashcam O=../output raspberrypicm4io_64_dev_dashcam_defconfig && cd output && make -j$(nproc)' 2>&1 | tail -50
        ;;
    custom|*)
        docker run --rm \
            -v "${SCRIPT_DIR}:/dashcam" \
            -v "${HOST_CCACHE}:/dashcam/.buildroot-ccache" \
            -w /dashcam \
            "${IMAGE_NAME}" \
            bash -c 'mkdir -p output && make -C buildroot/ BR2_EXTERNAL=../dashcam O=../output raspberrypicm4io_64_clean_dashcam_defconfig && cd output && make -j$(nproc)' 2>&1 | tail -50
        ;;
esac

# Step 3: Check result
echo ">>> Step 3: Checking build result..."
if [ -f "${HOST_OUTPUT}/images/sdcard.img" ]; then
    IMG_SIZE=$(stat --format="%s" "${HOST_OUTPUT}/images/sdcard.img")
    IMG_SIZE_MB=$((IMG_SIZE / 1048576))
    echo ""
    echo "========================================"
    echo " BUILD SUCCESSFUL"
    echo "========================================"
    echo " Image: ${HOST_OUTPUT}/images/sdcard.img"
    echo " Size:  ${IMG_SIZE_MB} MB"
    echo ""
    echo " To flash to any USB/SD card:"
    echo "   sudo ${SCRIPT_DIR}/flash.sh /dev/sdX"
    echo "========================================"
else
    echo "========================================"
    echo " BUILD INCOMPLETE — sdcard.img not found"
    echo " The build may still be running or failed."
    echo " Output dir: ${HOST_OUTPUT}"
    echo "========================================"
    exit 1
fi