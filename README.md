# HiveHacker

### Turn your Hivemapper HDC into a clean, high-end standalone dashcam.

**Website:** [hivehacker.ca](https://hivehacker.ca)  
**Author:** Eurisko2020  
**License:** MIT

---

## What is HiveHacker?

HiveHacker replaces the factory Hivemapper firmware with a clean, purpose-built dashcam operating system. No Hivemapper app, no token mining, no cloud — just a proper dashcam with H.264 hardware encoding, loop recording, G-sensor impact protection, parking mode, and a web dashboard you control from your phone.

The Hivemapper HDC is excellent hardware (Raspberry Pi CM4 + Sony IMX477 camera + GPS + IMU) trapped behind firmware that captures individual JPEG frames instead of real video. HiveHacker unlocks the hardware's full potential using the BCM2711's dedicated hardware video encoder to produce proper H.264 MP4 files at 1080p30.

## Key Improvements Over Stock Firmware

| Feature | Stock Hivemapper | HiveHacker |
|---------|------------------|------------|
| Video format | 72,000 JPEGs/hour | H.264 MP4 files |
| Storage/hour | ~72 GB | ~2-5 GB |
| Playback | Open files one by one | Play in any video player |
| Hardware encoder | Unused | Active (zero CPU) |
| Loop recording | Basic folder purge | Configurable segments + event locking |
| G-sensor protection | None | Impact detection + file locking |
| Parking mode | None | Motion-triggered recording |
| Web interface | None | Full dashboard from your phone |
| Cloud dependency | Required | None — fully offline |
| Wi-Fi | Hivemapper app controlled | Unique auto-generated SSID per device |

## Quick Start

### 1. Build the firmware
```bash
git clone --recurse-submodules https://github.com/Eurisko2020/hivehacker.git
cd hivehacker
./docker-build.sh
```
Requires Docker. Build takes 30-60 minutes (first time). Works on any Linux host.

### 2. Create a USB update stick
```bash
sudo ./usb-update.sh /dev/sdX
```
Formats a USB drive as FAT32 and copies the signed update bundle.

### 3. Flash your HDC (no disassembly)
1. Power OFF your HDC
2. Insert the USB stick
3. Power ON
4. Wait 2-3 minutes — device reboots automatically

### 4. Connect
1. Find Wi-Fi network: `hivehackerXXXX` (unique per device)
2. Password: `hivehak!`
3. Open browser: `http://192.168.0.10`

That's it. No case opening, no buttons, no rpiboot. The HDC's built-in A/B update system handles everything with automatic rollback if the new firmware fails.

## Features

- **H.264/HEVC hardware encoding** at 1080p30 via BCM2711 V4L2 encoder (zero CPU)
- **Loop recording** with configurable segment duration (1-10 minutes)
- **G-sensor impact detection** — locks current segment on impact, adjustable threshold
- **Parking mode** — low-power motion-triggered recording with pre-event buffer
- **GPS/IMU telemetry** — JSON metadata sidecars with full track data per segment
- **Web dashboard** — file browser, live preview, settings, events log, system controls
- **Unique Wi-Fi per device** — auto-generated SSID from hardware serial number
- **Multiple device support** — one build, unlimited devices, each with unique Wi-Fi
- **Fully offline** — no internet, no cloud, no telemetry, no account required
- **A/B updates with rollback** — failed boot auto-reverts to previous firmware
- **Read-only root filesystem** — power-loss safe, corrupt-proof system files
- **Hardware watchdog** — auto-reboot on hang
- **SSH access** — key-based auth for power users

## Documentation

- [BUILD.md](BUILD.md) — Full build, flash, and restore instructions
- [CONTRIBUTING.md](CONTRIBUTING.md) — How to contribute, code structure, testing
- [Website](https://hivehacker.ca) — Features, guides, and community

## Install Methods

| Method | Disassembly? | Reversible? | Recommended? |
|--------|-------------|-------------|--------------|
| USB update (Rauc A/B) | No | Yes (auto-rollback) | Yes — easiest |
| SD card boot | Yes (jumper) | Yes (remove card) | For testing |
| eMMC flash (rpiboot) | Yes (button) | Yes (with backup) | For permanent install |

## Multiple Devices

Build once, flash unlimited HDC devices. Each device auto-generates its own unique Wi-Fi SSID (`hivehackerXXXX`) based on its hardware serial number. Multiple dashcams in the same location don't conflict.

## Going Back to Stock

The USB update method uses A/B partitions — your original Hivemapper firmware stays on the other partition. If HiveHacker fails to boot 10 times, the device automatically reverts. You can also reflash the original firmware via USB at any time.

## Hardware Compatibility

- Hivemapper HDC (all variants — 8/16/32 GB eMMC, with or without LoRa)
- Raspberry Pi CM4 I/O board with IMX477 camera module

## Tech Stack

- **Buildroot** — embedded Linux build system
- **libcamera** — open-source camera framework with IMX477 support
- **V4L2 hardware encoder** — BCM2711's built-in H.264/HEVC encoder
- **Flask + nginx** — web dashboard
- **hostapd + dnsmasq** — Wi-Fi AP and DHCP
- **dropbear** — lightweight SSH
- **GPSD** — GPS daemon
- **Rauc** — A/B firmware updates with signed bundles

## Roadmap

- **Phase 1 (current):** Core dashcam — H.264 recording, loop storage, G-sensor, parking mode, web UI
- **Phase 2:** GPS OSD overlay, web UI firmware update, diagnostic tools
- **Phase 3:** ADAS (lane departure, collision warning), RTSP streaming, WebRTC preview
- **Phase 4:** Dual-camera support, plugin system, home automation integration

## Community

- [GitHub Discussions](https://github.com/Eurisko2020/hivehacker/discussions) — questions and help
- [GitHub Issues](https://github.com/Eurisko2020/hivehacker/issues) — bugs and feature requests
- [hivehacker.ca](https://hivehacker.ca) — documentation and guides

## Credits

- **Code by:** Eurisko2020
- **Built on:** [Hivemapper HDC firmware](https://github.com/Hivemapper/hdc_firmware) (MIT licensed)
- **Camera framework:** [libcamera](https://libcamera.org/)
- **Build system:** [Buildroot](https://buildroot.org/)
- **Update system:** [Rauc](https://rauc.readthedocs.io/)

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*HiveHacker is an independent open-source project by Eurisko2020 and is not affiliated with or endorsed by Hivemapper. Visit [hivehacker.ca](https://hivehacker.ca) for more information.*