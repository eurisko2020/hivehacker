<div align="center">

# 🐝 HiveHacker

### Free Your Hivemapper HDC — Turn It Into a High-End Standalone Dashcam

**Professional dashcam firmware. Open source. No strings. No cloud. No disassembly.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: RPi CM4](https://img.shields.io/badge/Platform-RPi%20CM4%20%2B%20IMX477-blue.svg)](https://www.raspberrypi.com/products/compute-module-4/)
[![Codec: H.264](https://img.shields.io/badge/Codec-H.264%20%2F%20HEVC-red.svg)](https://en.wikipedia.org/wiki/Advanced_Video_Coding)

🌍 **Website:** [www.hivehacker.ca](https://www.hivehacker.ca) · 
💻 **Code by:** Eurisko2020 · 
📖 **Docs:** [BUILD.md](BUILD.md) · [CONTRIBUTING.md](CONTRIBUTING.md)

</div>

---

## 🎯 What Is HiveHacker?

HiveHacker replaces the factory Hivemapper firmware with a clean, purpose-built dashcam operating system. No Hivemapper app. No token mining. No cloud. No phone-home. Just a proper dashcam with **H.264 hardware encoding**, **loop recording**, **G-sensor impact protection**, **parking mode**, and a **web dashboard you control from your phone**.

The Hivemapper HDC is excellent hardware — a Raspberry Pi Compute Module 4 with a Sony IMX477 camera sensor, GPS, IMU, and Wi-Fi, all in a car-ready enclosure. But the stock firmware captures **72,000 individual JPEG photos per hour** instead of real video. HiveHacker unlocks the hardware's full potential using the BCM2711's **dedicated hardware video encoder** to produce proper H.264 MP4 files at 1080p30.

> *"The dashcam Hivemapper should have shipped."*

---

## ⚡ The Problem — What's Wrong with Stock Firmware?

The Hivemapper HDC is $300+ hardware trapped behind firmware that doesn't use it properly:

### 📸 It Records JPEGs, Not Video
The factory firmware captures individual JPEG frames at 10fps — roughly **72,000 individual photos per hour**. There's no real video file. You can't play it in VLC. You can't share it. You can't edit it. It's a folder full of images.

### 💾 It Eats Storage Like Crazy
Those 72,000 JPEGs per hour take up **72+ GB of storage every hour**. A 32GB device fills up in under 30 minutes of driving. HiveHacker uses proper H.264 hardware encoding — the same codec used by professional cameras — giving you **2-5 GB per hour**. That's **15x less storage** for the same footage.

### 🔗 It's Locked to Hivemapper
The stock firmware requires the Hivemapper phone app for basic functionality. It runs token mining and map contribution logic in the background. It phones home to Hivemapper's servers. You don't control your own device.

### 🏭 The Hardware Encoder Is Wasted
The BCM2711 chip inside the HDC has a **dedicated hardware video encoder** capable of H.264 and HEVC encoding at 1080p30 with zero CPU usage. The stock firmware **doesn't use it at all**. HiveHacker puts it to work.

### 🚫 No Real Dashcam Features
No loop recording. No G-sensor impact protection. No parking mode. No emergency file locking. No browser-based file access. These are features every **$50 dashcam** has — the **$300+ HDC doesn't**.

---

## ✅ The Solution — What HiveHacker Does

HiveHacker is a **complete firmware replacement** — not a patch, not a tweak, not a settings change. The entire Hivemapper software stack is removed and replaced with a lean, focused dashcam system.

### The Core Upgrade: Real Video Recording

| Feature | Stock Hivemapper | HiveHacker |
|---------|:----------------:|:----------:|
| Video format | 72,000 JPEGs/hour | ✅ H.264 MP4 files |
| Storage/hour | ~72 GB | ✅ ~2-5 GB |
| Playback | Open files one by one | ✅ Play in any player |
| Hardware encoder | Unused | ✅ Active (zero CPU) |
| File format | Individual .jpg | ✅ Standard .mp4 |
| Loop recording | Basic folder purge | ✅ Configurable segments |
| Event protection | None | ✅ G-sensor locks segments |
| Parking mode | None | ✅ Motion-triggered recording |
| Web interface | None | ✅ Full dashboard from phone |
| Cloud dependency | Required | ✅ None — fully offline |

### What Gets Removed
- ❌ Hivemapper phone app dependency
- ❌ Token mining and map contribution
- ❌ Hivemapper network connectivity
- ❌ Cloud upload / telemetry / phone-home
- ❌ Object detection / TFLite models
- ❌ LoRaWAN logger
- ❌ Wi-Fi Direct P2P mode
- ❌ The JPEG frame capture pipeline

### What Gets Added
- ✅ H.264/HEVC hardware video encoding at 1080p30
- ✅ Loop recording with configurable segments (1-10 min)
- ✅ G-sensor impact detection and file locking
- ✅ Parking mode with motion-triggered recording
- ✅ GPS/IMU telemetry metadata (JSON sidecars)
- ✅ Web dashboard accessible from your phone
- ✅ File browser with download/delete/lock/unlock
- ✅ Settings page — change everything live, no reboot
- ✅ Events log with timeline and CSV export
- ✅ System controls (reboot, shutdown, diagnostics)
- ✅ Unique auto-generated Wi-Fi SSID per device
- ✅ SSH access for power users
- ✅ Hardware watchdog with auto-reboot
- ✅ Read-only root filesystem for power-loss safety
- ✅ A/B partition updates with automatic rollback

---

## 🌟 Features In Detail

### 🎥 Video Recording
Record continuous H.264 video at **1920x1080 at 30fps** using the BCM2711's dedicated hardware encoder. Zero CPU overhead — the encoder is a separate silicon block that runs independently.

- **Resolution:** 1080p (default), 720p, or 1640x922
- **Codec:** H.264 (default) or H.265/HEVC for 40% smaller files
- **Bitrate:** 4-20 Mbps, adjustable live from your phone
- **Framerate:** 24, 25, or 30 fps
- **Segment length:** 1-10 minutes, configurable
- Each segment is a **standalone MP4 file** with fast-start metadata — open it in any player, on any device, instantly
- Recording starts automatically **within 15 seconds** of power-on
- No frame drops during continuous recording

### 🔄 Loop Recording & Storage Management
Never run out of space. HiveHacker automatically manages storage so you always have the latest footage.

- Automatic deletion of oldest unlocked segments when storage reaches 85% (configurable)
- Purges down to 80% to avoid constant cycling
- Real-time storage usage displayed on the dashboard
- Supports eMMC (internal) or microSD (external) or both
- **32GB** = ~7 hours of H.264 loop recording
- **128GB microSD** = ~28 hours of continuous recording
- **HEVC mode: 128GB = ~47 hours**

### 💥 G-Sensor Impact Protection
When the IMU detects an impact above the configurable threshold, HiveHacker automatically **locks the current and previous segments** so they can't be deleted by the loop recorder.

- Sensitivity: 0.3G to 2.0G, adjustable from your phone
- Debounce: 0-200ms to prevent false triggers on rough roads
- Locked files survive the loop deletion process
- LED flashes rapidly for 5 seconds after event
- Event logged with timestamp, G-force magnitude, and segment filename
- View all events on the Events timeline page
- Export events log as CSV

### 🅿️ Parking Mode
When you park, HiveHacker goes into **low-power surveillance mode**.

- Automatically enters parking mode after 5 minutes of no GPS movement (configurable: 1-30 min)
- Stops continuous recording to save power and storage
- Keeps the IMU interrupt active — detects motion or impact instantly
- On motion event: records **30 seconds before** (ring buffer) + **60 seconds after**
- Parking mode recordings are auto-locked for 7 days
- LED slow-pulses to indicate parking mode is active
- Exits parking mode automatically when GPS detects movement
- Optional: disable Wi-Fi in parking mode for maximum power savings

### 📡 GPS & Telemetry
Every segment gets a **JSON metadata sidecar** with full GPS track and IMU summary data.

- GPS: NMEA parsing at 1Hz (or 10Hz if hardware supports)
- Tracks latitude, longitude, altitude, speed, heading, satellite count
- IMU: accelerometer and gyroscope at 50Hz
- Optional OSD overlay: burn timestamp, speed, and GPS coordinates into the video
- Configurable OSD format string and screen position
- Download metadata as JSON or CSV alongside any recording
- Speed display in km/h or mph (configurable)

### 📱 Web Dashboard
The dashcam serves a **full web interface** accessible from your phone browser. Connect to the dashcam's Wi-Fi, open `http://192.168.0.10`, and you have full control.

**Dashboard Home:** Mode status, GPS info, storage bar, CPU temp, uptime, current segment, Wi-Fi clients, LED state, quick actions

**Live Preview:** Real-time camera stream in your browser, full-screen mode, use it to check camera angle before mounting

**File Browser:** All recordings listed by date/size/locked status, filter tabs (All / Today / Locked / Events), download to phone, play inline, lock/unlock, delete, metadata download, bulk actions

**Settings Page (all live, no reboot):**
- Video: resolution, codec, bitrate, framerate, segment length, recording mode
- Storage: max usage, target free space, storage device, locked retention
- G-Sensor: sensitivity, debounce, pre/post buffers, test button
- Parking: entry timeout, exit trigger, Wi-Fi in parking, buffers
- GPS: OSD overlay, format, position, sample rate, timezone, speed unit
- Wi-Fi: SSID, password, channel, IP, DHCP range, on/off toggle
- LED: brightness, on/off toggle (stealth mode)
- Security: web UI password, SSH auth, authorized keys

**Events Log:** Timeline of all impact/parking events, G-force magnitude, linked segments, CSV export, date/type filtering

**System Controls:** Reboot, shutdown, firmware update, factory reset, diagnostic logs, SSH key management, firmware info

**Advanced Panel (power users):** Raw libcamera-vid command, debug logging, manual recording control, force parking mode, LED pattern test, raw GPS NMEA viewer, raw IMU data graph, V4L2 device info, storage benchmark, camera info

### 📶 Wi-Fi & Connectivity
Each HiveHacker device **auto-generates a unique Wi-Fi network name** based on its hardware serial number.

- SSID: `hivehackerXXXX` (where XXXX = last 4 hex of device serial)
- Password: `hivehak!`
- WPA2-PSK with CCMP encryption
- 2.4GHz (default) or 5GHz support
- Device IP: 192.168.0.10
- DHCP for connected clients
- mDNS: `dashcam.local` resolves to the device
- SSH access (key-based by default, password optional)
- **Multiple devices in the same location each get their own network** — no conflicts

### 🛡️ Reliability & Safety
- **Read-only root filesystem** — system files survive power loss
- **Hardware watchdog** — auto-reboots if the system hangs (30s timeout)
- **Atomic file writes** — power loss during recording doesn't corrupt segments
- **Camera pipeline auto-restart** on encoder failure (3 retries, then error LED)
- **Graceful shutdown** on power loss detection
- **A/B partition updates with automatic rollback** — if new firmware fails to boot 10 times, device reverts to previous firmware

### 🔒 Privacy
- **Fully offline** — no internet connection required or desired
- **No cloud upload, no telemetry, no analytics, no phone-home**
- All recordings stay on the device
- You control your data — download via Wi-Fi or SSH, delete anytime
- No account, no registration, no subscription

---

## 🚀 Quick Start

### What You Need
1. A Hivemapper HDC dashcam
2. A USB flash drive (any size, 1GB+)
3. A computer running Linux, macOS, or Windows (with Docker)
4. 30-60 minutes for the build (first time only — subsequent builds use cache)

### Step 1: Build the Firmware
```bash
git clone --recurse-submodules https://github.com/eurisko2020/hivehacker.git
cd hivehacker
./docker-build.sh
```

The build runs inside a Docker container pinned to Ubuntu 20.04 for compatibility. It compiles the Linux kernel, U-Boot bootloader, root filesystem, and all dashcam software. The output is a signed update bundle (`update.raucb`) and a full disk image (`sdcard.img`).

### Step 2: Create the USB Update Stick
```bash
sudo ./usb-update.sh /dev/sdX
```

This formats your USB drive as FAT32, creates a `hivemapper_update/` directory, and copies the signed update bundle into it. Safety checks prevent touching your system disk.

### Step 3: Flash Your HDC (No Disassembly!)
1. **Power OFF** your HDC dashcam
2. Insert the USB drive into the HDC's USB port
3. **Power ON** the HDC
4. Wait **2-3 minutes** — the LEDs will turn off and back on a couple times
5. The HDC **automatically reboots** into HiveHacker

That's it. **No case opening. No buttons. No rpiboot.** The HDC's built-in A/B update system reads the signed bundle from the USB, verifies the cryptographic signature, installs it to the inactive partition, and reboots.

### Step 4: Connect
1. On your phone or laptop, scan for Wi-Fi networks
2. Look for a network named **`hivehackerXXXX`** (e.g., hivehackerA3F2)
3. Connect with password: **`hivehak!`**
4. Open your browser and go to **`http://192.168.0.10`**
5. You're in — the HiveHacker dashboard loads

From here you can watch the live camera preview, browse and download recordings, adjust all settings, view the events log, check system status, and update firmware.

---

## 🔧 How It Works (Technical Overview)

### The Hardware
The Hivemapper HDC is, under the hood, a **Raspberry Pi Compute Module 4** with:
- Broadcom BCM2711 SoC (quad-core Cortex-A72 @ 1.5GHz)
- 4GB LPDDR4 RAM
- Sony IMX477 camera sensor (12.3MP — the same sensor as the Raspberry Pi HQ Camera)
- U-blox GPS module
- 6-axis IMU (accelerometer + gyroscope)
- BCM43455 Wi-Fi/Bluetooth
- eMMC storage (8/16/32GB depending on variant)
- microSD card slot, USB-C port
- Automotive enclosure with LED status indicator

This is real, capable hardware — the kind you'd find in a $300+ dashcam. The problem was never the hardware. It was the firmware.

### The Camera Pipeline
```
IMX477 Sensor
    │
    ▼
BCM2711 ISP (libcamera: auto white balance, auto exposure, denoise)
    │
    ▼
libcamera-vid (capture at 1080p30)
    │
    ▼
V4L2 Hardware Encoder (/dev/video11) — H.264 High Profile, 10Mbps
    │
    ▼
MP4 Muxer (ffmpeg remux with faststart)
    │
    ▼
/mnt/data/recordings/20260620_143022.mp4
```

The entire encoding pipeline runs on **dedicated hardware** — the CPU stays under 30% usage during recording. This means the system can simultaneously record, serve the web UI, monitor the G-sensor, and parse GPS data without breaking a sweat.

### The Firmware Stack
HiveHacker is built on **Buildroot** — the same embedded Linux build system used by the stock Hivemapper firmware. We start from the Hivemapper firmware source tree, remove all Hivemapper-specific packages, and add our own:

- **dashcamd** — the core recording daemon (Python) managing camera, storage, sensors, and LED
- **dashcam-webui** — the web interface (Flask + nginx)
- **libcamera** — open-source camera framework with IMX477 support
- **V4L2 hardware encoder** — the BCM2711's built-in H.264/HEVC encoder
- **hostapd + dnsmasq** — Wi-Fi AP and DHCP
- **dropbear** — lightweight SSH server
- **GPSD** — GPS daemon
- **Rauc** — A/B firmware updates with signed bundles

The result is a lean, purpose-built dashcam operating system that boots in **15 seconds** and gets out of your way.

---

## 📦 Install Methods

| Method | Disassembly? | Reversible? | Recommended? |
|--------|:-----------:|:-----------:|:------------:|
| **USB update (Rauc A/B)** | **No** | **Yes** (auto-rollback) | **✅ Yes — easiest** |
| SD card boot | Yes (jumper) | Yes (remove card) | For testing |
| eMMC flash (rpiboot) | Yes (button) | Yes (with backup) | For permanent install |

### Multiple Devices
Build once, flash **unlimited HDC devices**. Each device auto-generates its own unique Wi-Fi SSID (`hivehackerXXXX`) based on its hardware serial number. Multiple dashcams in the same location don't conflict.

### Going Back to Stock
The USB update method uses A/B partitions — your original Hivemapper firmware stays on the other partition. If HiveHacker fails to boot 10 times, the device **automatically reverts**. You can also reflash the original firmware via USB at any time.

---

## 🗺️ Roadmap

| Phase | Status | Features |
|-------|--------|----------|
| **Phase 1 — Core** | ✅ Current | H.264 recording, loop storage, G-sensor, parking mode, web UI, Wi-Fi AP |
| **Phase 2 — Sensors** | 🔄 Planned | GPS OSD overlay, web UI firmware update, diagnostic tools, factory reset |
| **Phase 3 — Advanced** | 📋 Future | ADAS (lane departure, collision warning), RTSP streaming, WebRTC preview |
| **Phase 4 — Ecosystem** | 📋 Future | Dual-camera support, plugin system, home automation integration |

---

## 📊 Technical Specs

| Spec | Value |
|------|-------|
| **Resolution** | 1920x1080, 1280x720, 1640x922 |
| **Codecs** | H.264 (High Profile), H.265/HEVC (Main Profile) |
| **Bitrate** | 4-20 Mbps (configurable) |
| **Framerate** | 24, 25, 30 fps |
| **Segment duration** | 60-600 seconds |
| **Hardware encoder** | BCM2711 V4L2 M2M (zero CPU overhead) |
| **H.264 storage** | ~4.5 GB/hour at 10Mbps |
| **HEVC storage** | ~2.7 GB/hour at 6Mbps |
| **GPS** | U-blox NEO-M8N, 1Hz or 10Hz |
| **IMU** | 6-axis, 50Hz sampling |
| **G-sensor threshold** | 0.3-2.0G (configurable) |
| **Wi-Fi** | BCM43455, 802.11 b/g/n/ac, 2.4 + 5 GHz |
| **Boot time** | <15 seconds to recording |
| **CPU usage** | <30% during recording |
| **Power (recording)** | <5W |
| **Power (parking)** | <1.5W |
| **Watchdog** | 30s hardware watchdog |
| **Filesystem** | squashfs (read-only root) + ext4 (writable data) |
| **Updates** | Rauc A/B with automatic rollback |
| **Build system** | Buildroot + Docker (Ubuntu 20.04) |
| **Build time** | 30-60 min (first), 5-10 min (incremental) |
| **Image size** | ~745 MB (sdcard.img), ~93 MB (update.raucb) |

---

## 📋 Hardware Compatibility

- ✅ Hivemapper HDC (all variants — 8/16/32 GB eMMC, with or without LoRa)
- ✅ Raspberry Pi CM4 I/O board with IMX477 camera module

---

## ❓ FAQ

**Is this legal?** Yes. The Hivemapper HDC firmware is open source (MIT license). The hardware is yours — you bought it. HiveHacker is an open-source firmware replacement that runs on hardware you own.

**Do I need to open the case?** No. The USB update method requires no disassembly. Just plug in a USB stick and power cycle.

**Can I still use the Hivemapper app?** No. HiveHacker removes all Hivemapper software. The device becomes a standalone dashcam with no connection to the Hivemapper ecosystem.

**Can I use this on multiple devices?** Yes. Build once, flash unlimited devices. Each gets its own unique Wi-Fi SSID automatically.

**Does it need internet?** No. HiveHacker is fully offline. No internet connection is required at any point — not for building, flashing, or running.

**What if the firmware doesn't boot?** The A/B partition system automatically falls back to the previous firmware after 10 failed boot attempts. You're never permanently bricked.

**Can I change the Wi-Fi password?** Yes. Connect to the dashcam's Wi-Fi, open `http://192.168.0.10/settings`, and change it. Takes effect immediately.

---

## 🤝 Community & Contributing

- 💬 [GitHub Discussions](https://github.com/eurisko2020/hivehacker/discussions) — questions and help
- 🐛 [GitHub Issues](https://github.com/eurisko2020/hivehacker/issues) — bugs and feature requests
- 📖 [CONTRIBUTING.md](CONTRIBUTING.md) — how to contribute, code structure, testing
- 🌍 [www.hivehacker.ca](https://www.hivehacker.ca) — documentation and guides

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full code structure, coding guidelines, and testing instructions.

---

## 🙏 Credits

- **Code by:** [Eurisko2020](https://github.com/eurisko2020)
- **Built on:** [Hivemapper HDC firmware](https://github.com/Hivemapper/hdc_firmware) (MIT licensed)
- **Camera framework:** [libcamera](https://libcamera.org/)
- **Build system:** [Buildroot](https://buildroot.org/)
- **Update system:** [Rauc](https://rauc.readthedocs.io/)

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">

**🐝 HiveHacker** — *Your Hardware. Your Firmware. Your Dashcam.*

*"Stop mining. Start recording."*

🌍 [www.hivehacker.ca](https://www.hivehacker.ca) · 💻 [GitHub](https://github.com/eurisko2020/hivehacker) · 📧 MIT License

*HiveHacker is an independent open-source project by Eurisko2020 and is not affiliated with or endorsed by Hivemapper.*

</div>