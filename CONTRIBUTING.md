# Contributing to HiveHacker

Thank you for your interest in contributing to HiveHacker! This project turns the Hivemapper HDC dashcam into a clean, standalone, high-end dashcam with open-source firmware.

**Official website:** [hivehacker.ca](https://hivehacker.ca)  
**Code by:** Eurisko2020

---

## Ways to Contribute

### Report Bugs
- Open an issue on GitHub with the tag "bug"
- Include: device variant, firmware version, steps to reproduce, expected vs actual behavior
- Attach the diagnostic log from the web UI (System > Download Diagnostic Log)

### Request Features
- Open an issue on GitHub with the tag "feature request"
- Describe the feature and your use case
- Check the roadmap first — it may already be planned

### Submit Code
- Fork the repository
- Create a feature branch: `git checkout -b my-feature`
- Make your changes
- Test on real hardware if possible
- Submit a pull request with a clear description of what and why

### Help Others
- Answer questions in GitHub Discussions
- Share your experience with different HDC hardware variants
- Write guides, tips, and configurations in the Wiki

### Test on Hardware
- We need testers with different HDC variants (different eMMC sizes, with/without LoRa)
- Report what works and what doesn't
- Test parking mode, G-sensor sensitivity, GPS fix times, thermal behavior

---

## Development Setup

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/Eurisko2020/hivehacker.git
cd hivehacker

# Build in Docker (works on any Linux host)
./docker-build.sh

# For development, open a shell in the build container
./docker-build.sh shell
```

See [BUILD.md](BUILD.md) for full build and flash instructions.

---

## Code Structure

```
hdc_firmware/
├── Dockerfile.build          # Build environment (Ubuntu 20.04, GCC 9)
├── docker-build.sh           # Main build entry point
├── flash.sh                  # Flash to USB/SD/eMMC (with backup + restore)
├── usb-update.sh             # Create FAT32 USB update stick
├── build.sh                  # Internal build script (runs in container)
├── LICENSE                   # MIT License
├── BUILD.md                  # Build & flash documentation
│
├── buildroot/                # Hivemapper's Buildroot fork (submodule)
├── dashcampublicpatches/     # Public patches (submodule)
│
└── dashcam/                  # Our custom packages and board config
    ├── Config.in             # Package registration
    │
    ├── configs/
    │   └── raspberrypicm4io_64_clean_dashcam_defconfig  # Custom Buildroot config
    │
    ├── board/
    │   └── raspberrypicm4io_64_clean/
    │       ├── linux.fragment              # Kernel config (V4L2 encoder, I2C, etc.)
    │       ├── post_build.sh               # Post-build customization
    │       └── overlays/common/
    │           ├── etc/hostapd.conf        # Wi-Fi AP config
    │           ├── etc/dnsmasq.conf        # DHCP/DNS config
    │           ├── etc/dashcamd.conf       # Dashcam daemon config
    │           ├── etc/systemd/system/
    │           │   └── generate-ssid.service  # Unique SSID at boot
    │           └── opt/dashcam/bin/
    │               └── generate-ssid.sh    # SSID generator script
    │
    └── package/
        ├── dashcamd/           # Core recording daemon
        │   ├── Config.in
        │   ├── dashcamd.mk
        │   ├── dashcamd.service
        │   ├── dashcamd.conf
        │   └── src/
        │       ├── dashcamd.py          # Main daemon
        │       ├── config_loader.py     # Config management
        │       ├── camera_worker.py     # H.264 recording via libcamera-vid
        │       ├── storage_worker.py    # Loop deletion + event locking
        │       ├── gps_worker.py        # NMEA parsing
        │       ├── imu_worker.py        # G-sensor impact detection
        │       ├── led_worker.py        # LED status indicator
        │       └── parking_worker.py    # Parking mode state machine
        │
        └── dashcam-webui/     # Web interface
            ├── Config.in
            ├── dashcam-webui.mk
            ├── dashcam-webui.service
            └── src/
                ├── app.py               # Flask app + REST API
                ├── templates/           # HTML templates
                │   ├── base.html
                │   ├── index.html       # Dashboard
                │   ├── recordings.html  # File browser
                │   ├── settings.html    # Settings page
                │   └── events.html      # Events log
                └── static/
                    ├── style.css        # Dark theme CSS
                    └── app.js           # Client-side JS
```

---

## Coding Guidelines

### Python (dashcamd, web UI)
- Python 3, no external dependencies beyond what's in the Buildroot tree
- Keep modules small and focused — one worker per concern
- Use logging, not print
- Handle hardware absence gracefully (GPS, IMU may not be present on all variants)
- Thread-safe shared state via the SharedState class

### Shell Scripts
- POSIX sh where possible, bash when needed
- Always use `set -euo pipefail`
- Safety checks before destructive operations (dd, rm, mkfs)
- Clear output messages with `>>>` prefix for actions

### Buildroot Packages
- Follow Buildroot packaging conventions
- Config.in with proper `select` dependencies
- .mk file with standard variable names
- systemd service files for daemons

---

## Testing

If you have an HDC device:
1. Build the firmware: `./docker-build.sh`
2. Create a USB update stick: `sudo ./usb-update.sh /dev/sdX`
3. Flash your device (USB update method — no disassembly)
4. Test and report results in GitHub Discussions

Key things to test:
- Does the camera produce H.264 MP4 files?
- Does the Wi-Fi AP appear with a unique hivehackerXXXX SSID?
- Can you access the web UI at http://192.168.0.10?
- Does loop recording work (fill storage, verify old files are deleted)?
- Does the G-sensor detect impacts (test with the test button in settings)?
- Does parking mode enter/exit correctly?
- Does GPS get a fix and record metadata?

---

## Questions?

- GitHub Discussions for general questions
- GitHub Issues for bugs and feature requests
- Visit [hivehacker.ca](https://hivehacker.ca) for documentation and guides

---

*HiveHacker is an independent open-source project by Eurisko2020 and is not affiliated with or endorsed by Hivemapper.*