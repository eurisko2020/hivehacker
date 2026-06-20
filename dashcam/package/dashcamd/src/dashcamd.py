#!/usr/bin/env python3
"""
dashcamd - Core Dashcam Recording Daemon
For Hivemapper HDC (CM4 + IMX477) - Clean Dashcam Firmware

Replaces: camera-bridge, folder-purger, camera-node, data-logger, led-controller
Records H.264/HEVC via libcamera-vid + V4L2 hardware encoder instead of JPEG frames.
"""

import os
import sys
import time
import json
import signal
import logging
import subprocess
import threading
from pathlib import Path
from datetime import datetime, timezone

# Add our module path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from config_loader import ConfigLoader

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(name)s] %(levelname)s: %(message)s',
    handlers=[
        logging.FileHandler('/mnt/data/logs/dashcamd.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('dashcamd')

# Shared state between workers
class SharedState:
    def __init__(self):
        self.mode = 'RECORDING'  # RECORDING, PARKING, ERROR
        self.recording = False
        self.current_segment = None
        self.gps_data = {}
        self.imu_data = {}
        self.events = []
        self.locked_files = set()
        self.storage_usage = 0
        self.cpu_temp = 0
        self.wifi_clients = 0
        self.led_state = 'RECORDING'
        self.config = None
        self.shutdown_flag = False

state = SharedState()


def read_cpu_temp():
    """Read CPU temperature from sysfs."""
    try:
        with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
            return float(f.read().strip()) / 1000.0
    except Exception:
        return 0.0


def signal_handler(signum, frame):
    """Handle shutdown signals gracefully."""
    logger.info(f"Received signal {signum}, shutting down...")
    state.shutdown_flag = True


def main():
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    # Load configuration
    config_path = os.environ.get('DASHCAM_CONFIG', '/etc/dashcamd.conf')
    state.config = ConfigLoader(config_path)
    logger.info(f"Configuration loaded from {config_path}")

    # Ensure directories exist
    Path('/mnt/data/recordings').mkdir(parents=True, exist_ok=True)
    Path('/mnt/data/recordings/.meta').mkdir(parents=True, exist_ok=True)
    Path('/mnt/data/recordings/LOCKED').mkdir(parents=True, exist_ok=True)
    Path('/mnt/data/events').mkdir(parents=True, exist_ok=True)
    Path('/mnt/data/logs').mkdir(parents=True, exist_ok=True)
    Path('/mnt/data/config').mkdir(parents=True, exist_ok=True)

    # Import and start workers
    from camera_worker import CameraWorker
    from storage_worker import StorageWorker
    from led_worker import LEDWorker

    # Start workers in threads
    workers = []

    camera = CameraWorker(state)
    storage = StorageWorker(state)
    led = LEDWorker(state)

    # Start GPS worker if GPS is configured
    try:
        from gps_worker import GPSWorker
        gps = GPSWorker(state)
        workers.append(gps)
    except Exception as e:
        logger.warning(f"GPS worker not started: {e}")

    # Start IMU worker if I2C is available
    try:
        from imu_worker import IMUWorker
        imu = IMUWorker(state)
        workers.append(imu)
    except Exception as e:
        logger.warning(f"IMU worker not started: {e}")

    # Start parking mode worker
    try:
        from parking_worker import ParkingWorker
        parking = ParkingWorker(state)
        workers.append(parking)
    except Exception as e:
        logger.warning(f"Parking worker not started: {e}")

    # Core workers always start
    workers.append(camera)
    workers.append(storage)
    workers.append(led)

    # Start all workers
    for w in workers:
        w.start()
        logger.info(f"Started worker: {w.__class__.__name__}")

    state.recording = True
    logger.info("dashcamd started - recording active")

    # Main loop - monitor state, update status
    while not state.shutdown_flag:
        state.cpu_temp = read_cpu_temp()

        # Check for errors
        if state.mode == 'ERROR' and state.led_state != 'ERROR':
            state.led_state = 'ERROR'

        time.sleep(5)

    # Shutdown - stop all workers
    logger.info("Stopping all workers...")
    state.recording = False
    for w in workers:
        w.stop()
        logger.info(f"Stopped worker: {w.__class__.__name__}")

    logger.info("dashcamd stopped")


if __name__ == '__main__':
    main()