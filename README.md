<p align="center">
  <img src="docs/logo-banner.png" alt="HiveHacker Logo" width="400">
</p>

<h3 align="center">Free Your Hivemapper HDC — Turn It Into a High-End Standalone Dashcam</h3>

<p align="center">
  <b>Professional dashcam firmware. Open source. No strings. No cloud. No disassembly.</b>
</p>

<p align="center">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://www.raspberrypi.com/products/compute-module-4/"><img src="https://img.shields.io/badge/Platform-RPi%20CM4%20%2B%20IMX477-blue.svg" alt="Platform"></a>
  <a href="https://en.wikipedia.org/wiki/Advanced_Video_Coding"><img src="https://img.shields.io/badge/Codec-H.264%20%2F%20HEVC-red.svg" alt="Codec"></a>
</p>

<p align="center">
  🌍 <a href="https://www.hivehacker.ca"><b>www.hivehacker.ca</b></a> · 
  💻 Code by <b>Eurisko2020</b> · 
  📖 <a href="BUILD.md">Build Guide</a> · 
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

---

<p align="center">
  <img src="docs/logo-small.png" alt="HiveHacker" align="center">
</p>

## 🎯 What Is HiveHacker?

HiveHacker replaces the factory Hivemapper firmware with a clean, purpose-built dashcam operating system. No Hivemapper app. No token mining. No cloud. No phone-home. Just a proper dashcam with **H.264 hardware encoding**, **loop recording**, **G-sensor impact protection**, **parking mode**, and a **web dashboard you control from your phone**.

The Hivemapper HDC is excellent hardware — a Raspberry Pi Compute Module 4 with a Sony IMX477 camera sensor, GPS, IMU, and Wi-Fi, all in a car-ready enclosure. But the stock firmware captures **72,000 individual JPEG photos per hour** instead of real video. HiveHacker unlocks the hardware's full potential using the BCM2711's **dedicated hardware video encoder** to produce proper H.264 MP4 files at 1080p30.

> *"The dashcam Hivemapper should have shipped."*

---

<p align="center">
  <img src="docs/logo-small.png" alt="HiveHacker" align="center">
</p>

## ⚡ Key Improvements Over Stock

| Feature | Stock Hivemapper | HiveHacker |
|---------|:----------------:|:----------:|
| Video format | 72,000 JPEGs/hour | ✅ H.264 MP4 files |
| Storage/hour | ~72 GB | ✅ ~2-5 GB |
| Playback | Open files one by one | ✅ Play in any player |
| Hardware encoder | Unused | ✅ Active (zero CPU) |
| Captive portal | ❌ | ✅ Auto-opens dashboard on connect |
| Live view + REC indicator | ❌ | ✅ Real-time with blinking REC + timer |
| Loop recording | Basic folder purge | ✅ Configurable segments + event locking |
| G-sensor protection | None | ✅ Impact detection + file locking |
| Parking mode | None | ✅ Motion-triggered recording |
| Web dashboard | None | ✅ Full mobile-responsive UI |
| LED controls | Limited | ✅ 3 LEDs (Power/GPS/REC) with individual toggles |
| Email/SMTP | ❌ | ✅ Send recordings directly from browser |
| External USB management | ❌ | ✅ Format, mount, monitor storage |
| Cloud dependency | Required | ✅ None — fully offline |
| Wi-Fi per device | Fixed SSID | ✅ Auto-generated unique hivehackerXXXX |
| SSH access | Password only | ✅ Auto-generated password + key auth |
| Timezone support | ❌ | ✅ Local timestamps on all recordings |

---

<p align="center">
  <img src="docs/logo-small.png" alt="HiveHacker" align="center">
</p>

## 🌟 Features

### 🎥 Video Recording
- **H.264/HEVC hardware encoding** at 1080p30 via BCM2711 V4L2 encoder (zero CPU)
- Bitrate adjustable in **Mbps** (4-20 Mbps) — no confusing raw numbers
- Segment length: 1-10 minutes, configurable
- Each segment is a standalone MP4 — plays in any player instantly
- Recording starts automatically within 15 seconds of power-on

### 📱 Captive Portal + Live View
When you connect to the dashcam's Wi-Fi, the dashboard **automatically pops up** in your browser (iOS, Android, Windows). The main screen shows:
- **Live camera feed** with a **blinking REC indicator** and recording timer
- **Dual storage display** — Device (eMMC) + External USB, each with space used and estimated recording time remaining
- Status cards: mode, GPS, temperature, uptime, local time, locked recordings count
- Quick actions: View Recordings, Full Screen Live, Lock Current Segment

### 🔄 Loop Recording & Storage Management
Never run out of space. HiveHacker automatically manages storage:
- Automatic deletion of oldest unlocked segments at configurable threshold (70-95%)
- Supports eMMC (internal), microSD, or external USB, or both (USB overflow)
- **32GB = ~7 hours** H.264, **128GB = ~28 hours**, HEVC: **128GB = ~47 hours**

### 💥 G-Sensor Impact Protection
- Detects impacts (0.3G-2.0G, adjustable) and locks current segment
- LED flashes rapidly on event
- Events logged with timestamp, G-force, segment filename
- Sensitivity options: High / Medium / Low / Very Low

### 🅿️ Parking Mode
- Auto-enters after configurable timeout (1-30 min no movement)
- Motion-triggered recording with 30s pre-event buffer + 60s post-event
- Low-power mode with optional Wi-Fi disable
- Auto-exits when GPS detects movement

### 💡 LED Controls — 3 Physical LEDs with Apple-Style Toggles
<p align="center">
  <img src="docs/logo-small.png" alt="" width="32" align="center"> Three physical LEDs on the HDC, each independently controllable:
</p>

- **💡 Power LED** — solid when device is powered (toggle on/off)
- **📡 GPS LED** — solid when GPS has fix, blinks when searching (toggle on/off)
- **🔴 REC LED** — blinks red while recording, solid on event, slow pulse in parking mode (toggle on/off)
- Adjustable brightness (0-255)

### 📧 Email / SMTP — Send Recordings Directly
Configure your email server in Settings to **send recordings directly from the file browser**:
- SMTP settings (Gmail, Outlook, etc.)
- "Send" button on each recording opens email dialog
- Pre-filled subject and message, just enter recipient
- Perfect for sending footage to insurance, police, or family

### 🔌 External USB Management
- View connected USB drives with storage usage and time estimates
- **Format USB** button (erases and prepares for recording storage)
- **Eject** button for safe removal
- Select recording storage: Device / External USB / Both (overflow)

### 📡 GPS & Timezone
- **Local timezone support** (Eastern, Central, Mountain, Pacific, etc.)
- Recordings timestamped in local time
- Optional OSD overlay (timestamp + speed + GPS burned into video)
- Speed in km/h or mph

### 🎬 Recordings Browser
- Recordings listed with **thumbnails** by date/size/locked status
- **Play** recordings inline in browser video player
- **Send** via email (with SMTP configured)
- **Download** to phone
- **Lock/Unlock** individual files
- **Delete** unlocked files
- Filter: All / Today / Locked / Events
- Bulk actions

### ⚙️ Settings (All Live, No Reboot)
- **Video:** resolution, codec, bitrate (Mbps), framerate, segment length
- **Storage:** device selection, max usage, locked retention (7/14/30/90 days)
- **G-Sensor:** sensitivity (High/Medium/Low), test button
- **Parking:** entry timeout, exit trigger, Wi-Fi in parking
- **GPS:** timezone, speed unit, OSD overlay
- **LED:** individual toggles for Power/GPS/REC, brightness
- **Wi-Fi:** auto-generated unique SSID + password (read-only)
- **Email:** SMTP server, port, credentials, enable/disable toggle
- **Security:** web UI password (optional), SSH key management

### 🔄 Firmware Update
- **Upload .raucb via browser** — update directly from web UI
- **USB stick method** — documented in-app, no computer needed
- A/B partition with automatic rollback (10 failed boots = revert)

### 🔒 Privacy & Security
- **Fully offline** — no internet required at any point
- No cloud, telemetry, analytics, or phone-home
- SSH: auto-generated unique password per device (**hivehacksshXXXX**)
- SSH: key-based authentication supported
- WPA2-PSK Wi-Fi with unique SSID per device (**hivehackerXXXX** / **hivehak!**)

---

<p align="center">
  <img src="docs/logo-medium.png" alt="HiveHacker" width="256">
</p>

## 🚀 Quick Start

### 1. Build the Firmware
```bash
git clone --recurse-submodules https://github.com/eurisko2020/hivehacker.git
cd hivehacker
./docker-build.sh
```
Requires Docker. Build takes 30-60 minutes (first time).

### 2. Create USB Update Stick
```bash
sudo ./usb-update.sh /dev/sdX
```

### 3. Flash Your HDC (No Disassembly!)
1. Power OFF your HDC
2. Insert the USB stick
3. Power ON
4. Wait 2-3 minutes — LEDs will cycle
5. HDC reboots into HiveHacker

### 4. Connect
1. Find Wi-Fi: **hivehackerXXXX** (unique per device)
2. Password: **hivehak!**
3. Dashboard auto-opens in your browser
4. SSH: `ssh root@192.168.0.10` (password: **hivehacksshXXXX**)

---

<p align="center">
  <img src="docs/logo-small.png" alt="HiveHacker" width="48" align="center">
</p>

## 📊 Technical Specs

| Spec | Value |
|------|-------|
| Resolution | 1920x1080, 1280x720, 1640x922 |
| Codecs | H.264 (High Profile), H.265/HEVC |
| Bitrate | 4-20 Mbps (shown in Mbps, not raw numbers) |
| Framerate | 24, 25, 30 fps |
| Storage/hour | H.264: ~4.5 GB, HEVC: ~2.7 GB |
| GPS | U-blox, 1Hz/10Hz, local timezone support |
| IMU | 6-axis, 50Hz, 0.3-2.0G threshold |
| LEDs | 3 (Power/GPS/REC) with individual GPIO control + toggles |
| Wi-Fi | BCM43455, unique SSID per device |
| SSH | Auto-generated password + key auth |
| Boot time | <15 seconds |
| CPU usage | <30% during recording |
| Power | <5W recording, <1.5W parking |
| Updates | Rauc A/B with rollback + browser upload |
| Email | SMTP configurable (Gmail, Outlook, etc.) |

---

<p align="center">
  <img src="docs/logo-small.png" alt="HiveHacker" width="48" align="center">
</p>

## 📦 Install Methods

| Method | Disassembly? | Reversible? | Recommended? |
|--------|:-----------:|:-----------:|:------------:|
| **USB update (Rauc A/B)** | **No** | **Yes** (auto-rollback) | **✅ Yes** |
| SD card boot | Yes (jumper) | Yes (remove card) | For testing |
| eMMC flash (rpiboot) | Yes (button) | Yes (with backup) | Permanent |

Build once, flash unlimited devices. Each gets its own unique Wi-Fi + SSH password.

---

## 🗺️ Roadmap

| Phase | Status | Features |
|-------|--------|----------|
| Phase 1 — Core | ✅ Current | H.264, loop, G-sensor, parking, web UI, captive portal, LED control, SMTP email, USB management |
| Phase 2 — Polish | 🔄 Planned | GPS OSD overlay, video thumbnails, firmware update via web |
| Phase 3 — Advanced | 📋 Future | ADAS (lane departure, collision warning), RTSP streaming, WebRTC preview |
| Phase 4 — Ecosystem | 📋 Future | Dual-camera support, plugin system, home automation integration |

---

## ❓ FAQ

**Is this legal?** Yes. The Hivemapper HDC firmware is MIT licensed. The hardware is yours.

**Do I need to open the case?** No. USB update requires no disassembly.

**Can I use on multiple devices?** Yes. Each gets its own unique Wi-Fi + SSH password.

**Does it need internet?** No. Fully offline.

**What if firmware doesn't boot?** A/B auto-rolls back after 10 failed boots.

**Can I email recordings?** Yes. Configure SMTP in Settings, then use "Send" on any recording.

---

<p align="center">
  <img src="docs/logo-small.png" alt="HiveHacker" width="48" align="center">
</p>

## 🤝 Community

- 💬 [GitHub Discussions](https://github.com/eurisko2020/hivehacker/discussions) — questions and help
- 🐛 [GitHub Issues](https://github.com/eurisko2020/hivehacker/issues) — bugs and feature requests
- 🌍 [www.hivehacker.ca](https://www.hivehacker.ca) — documentation and guides

---

## 🙏 Credits

- **Code by:** [Eurisko2020](https://github.com/eurisko2020)
- **Built on:** [Hivemapper HDC firmware](https://github.com/Hivemapper/hdc_firmware) (MIT)
- **Camera:** [libcamera](https://libcamera.org/) · **Build:** [Buildroot](https://buildroot.org/) · **Updates:** [Rauc](https://rauc.readthedocs.io/)

## 📄 License

MIT License — see [LICENSE](LICENSE).

---

<p align="center">
  <img src="docs/logo-banner.png" alt="HiveHacker" width="300">
</p>

<h3 align="center">🐝 Your Hardware. Your Firmware. Your Dashcam.</h3>

<p align="center"><i>"Stop mining. Start recording."</i></p>

<p align="center">
  🌍 <a href="https://www.hivehacker.ca"><b>www.hivehacker.ca</b></a> · 
  💻 <a href="https://github.com/eurisko2020/hivehacker"><b>GitHub</b></a>
</p>

<p align="center">
  <i>HiveHacker is an independent open-source project by Eurisko2020<br>
  and is not affiliated with or endorsed by Hivemapper.</i>
</p>