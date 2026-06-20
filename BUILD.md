# HDC Clean Dashcam Firmware — Build & Flash Guide

## Prerequisites

1. **Linux host** (any modern distro — Ubuntu, Debian, Arch, etc.)
2. **Docker** installed and working
3. **USB drive or SD card** (8 GB minimum, 32+ GB recommended for recording storage)
4. **Hivemapper HDC** dashcam with USB-C cable (for eMMC flashing) or SD card slot

## Quick Start

### 1. Clone the repo
```bash
git clone --recurse-submodules https://github.com/Hivemapper/hdc_firmware.git
cd hdc_firmware
```

### 2. Build the firmware (Docker — works on any host)
```bash
./docker-build.sh          # builds custom clean dashcam image
```

This runs the entire Buildroot compilation inside a Docker container pinned to
Ubuntu 20.04 (for GCC 9 compatibility with the old Buildroot tree). It takes
30-60 minutes on the first run. Subsequent builds use ccache and are much faster.

Output: `output/images/sdcard.img`

### 3. Flash to USB/SD card
```bash
sudo ./flash.sh /dev/sdX
```

The script has safety checks:
- Refuses to flash your system disk
- Refuses to flash mounted devices
- Requires typing "YES" to confirm
- Auto-resizes the data partition to fill the entire card

### 3a. Flash to HDC internal eMMC (permanent install)
When you connect the HDC via USB-C in rpiboot mode, the eMMC appears as a block
device. The flash script detects this and offers to **back up the original
Hivemapper firmware** before overwriting:

```bash
sudo rpiboot                    # Put CM4 in USB mass storage mode
sudo ./flash.sh /dev/sdX       # Script detects eMMC, offers backup, then flashes
```

The backup is saved to `backups/firmware_backup_<timestamp>.img` with a metadata
file recording the device info, date, and restore instructions.

### 3b. Restore original firmware
If you ever want to go back to the original Hivemapper firmware:

```bash
# List available backups
sudo ./flash.sh backups

# Restore a specific backup
sudo ./flash.sh restore backups/firmware_backup_20260620_153000.img /dev/sdX
```

### 4. Install in the HDC

There are 3 ways to install the firmware. The USB update method is recommended —
no disassembly required.

**Option A: USB update (RECOMMENDED — no disassembly)**

This uses the HDC's built-in Rauc A/B update mechanism. The build produces a
signed `update.raucb` bundle. You put it on a FAT32 USB stick, plug it into
the powered-off HDC, and power on. The device auto-installs it and reboots.

```bash
# Create the USB update stick (formats the USB as FAT32 automatically)
sudo ./usb-update.sh /dev/sdX

# Or use an already-formatted FAT32 USB:
sudo ./usb-update.sh /dev/sdX noformat
```

Then:
1. Power OFF the HDC
2. Insert the USB stick into the HDC's USB port
3. Power ON the HDC
4. Wait 2-3 minutes (LEDs will turn off then back on a couple times)
5. The HDC reboots into the new firmware automatically

The old firmware stays on the other A/B partition as a fallback. If the new
firmware fails to boot, the device automatically falls back after 10 failed
boot attempts.

**Option B: SD card boot (non-destructive, reversible)**
- Insert the flashed SD card into the HDC's SD slot
- Set the CM4 boot jumper to boot from SD (requires opening the case)
- Power on
- Remove the SD card to go back to the original firmware

**Option C: eMMC via rpiboot (permanent, requires disassembly)**
- Open the HDC case to access the boot button/jumper
- Connect HDC to your computer via USB-C
- Hold the boot button for USB boot mode
- On your computer:
  ```bash
  sudo rpiboot
  sudo ./flash.sh /dev/sdX    # Script auto-backs up original firmware
  ```
- Reassemble, power cycle

### 4. Connect to Wi-Fi
Each device auto-generates a unique Wi-Fi SSID based on its serial number:
- SSID: `hivehackerXXXX` (where XXXX = last 4 of device serial)
- Password: `hivehak!`

This means multiple HDC devices in the same location each get their own Wi-Fi
network automatically — no manual configuration needed.
3. Connect to the Wi-Fi AP from your phone
4. Browse to `http://192.168.0.10`
5. You should see the dashcam dashboard

## Build Modes

| Command | Description |
|---------|-------------|
| `./docker-build.sh` | Build custom clean dashcam firmware (default) |
| `./docker-build.sh stock` | Build stock Hivemapper firmware (for reference) |
| `./docker-build.sh clean` | Full clean rebuild (removes ccache) |
| `./docker-build.sh shell` | Open a shell in the build container for debugging |

## Files Created

| File | Purpose |
|------|---------|
| `Dockerfile.build` | Docker image definition (Ubuntu 20.04 + build deps) |
| `docker-build.sh` | Main build entry point (runs build in Docker) |
| `build.sh` | Internal build script (runs inside the container) |
| `flash.sh` | Flash sdcard.img to any USB/SD card with safety checks |
| `dashcam/configs/raspberrypicm4io_64_clean_dashcam_defconfig` | Custom Buildroot defconfig |
| `dashcam/board/raspberrypicm4io_64_clean/` | Board-specific files (kernel fragment, hostapd, dnsmasq, dashcamd.conf) |
| `dashcam/package/dashcamd/` | Core recording daemon (Python) |
| `dashcam/package/dashcam-webui/` | Web UI (Flask + nginx) |
| `output/images/sdcard.img` | The flashable firmware image |

## Customizing

### Change Wi-Fi SSID/password at build time
Edit `dashcam/board/raspberrypicm4io_64_clean/overlays/common/etc/hostapd.conf`:
```
ssid=your_custom_name
wpa_passphrase=your_secure_password
```

### Change default recording settings
Edit `dashcam/board/raspberrypicm4io_64_clean/overlays/common/etc/dashcamd.conf`:
```ini
[camera]
width = 1920
height = 1080
framerate = 30
codec = h264
bitrate = 10000000
segment_duration = 180
```

### Change settings at runtime
Connect to the dashcam Wi-Fi and browse to `http://192.168.0.10/settings`.
Settings are saved to `/mnt/data/config/dashcamd.conf` and persist across reboots.

## Architecture

```
Host (any Linux)
  └── Docker container (Ubuntu 20.04, GCC 9)
       └── Buildroot
            ├── Linux kernel (bcm2711 + IMX477 + V4L2 encoder)
            ├── U-Boot (rpi_arm64)
            ├── Root filesystem (squashfs, read-only)
            └── Custom packages:
                 ├── dashcamd      (H.264 recording daemon)
                 └── dashcam-webui (Flask web interface)
  └── output/images/sdcard.img  (flashable image)
```

## Partition Layout (sdcard.img)

| Partition | Type | Size | Purpose |
|-----------|------|------|---------|
| env | U-Boot env | 32K | Bootloader environment |
| boot0 | FAT32 | 64M | Kernel, device tree, config.txt |
| rootfs0 | squashfs | 300M | Root filesystem (A/B slot 0) |
| rootfs1 | squashfs | 300M | Root filesystem (A/B slot 1) |
| data | ext4 | rest | Recordings, config, logs (auto-resized on flash) |