#!/usr/bin/env python3
"""
Parking Worker - Monitors GPS for no-movement and enters/exits parking mode.
In parking mode, keeps IMU interrupt active for motion-triggered recording.
"""

import time
import logging
import threading

logger = logging.getLogger('dashcamd.parking')


class ParkingWorker(threading.Thread):
    def __init__(self, state):
        super().__init__(daemon=True)
        self.state = state
        self._stop_flag = False
        self.last_movement_time = time.time()
        self.last_gps_speed = 0

    def run(self):
        opts = self.state.config.get_parking_opts()
        entry_timeout = opts['entry_timeout']
        exit_on_movement = opts['exit_on_movement']

        while not self._stop_flag:
            gps_data = self.state.gps_data.get('last_fix', {})
            current_speed = gps_data.get('speed_kmh', 0)

            # Detect movement (speed > 2 km/h)
            if current_speed > 2:
                self.last_movement_time = time.time()

            no_movement_duration = time.time() - self.last_movement_time

            if self.state.mode == 'RECORDING':
                if no_movement_duration >= entry_timeout:
                    self.enter_parking()
            elif self.state.mode == 'PARKING':
                if exit_on_movement and current_speed > 2:
                    self.exit_parking()

            time.sleep(10)  # Check every 10 seconds

    def enter_parking(self):
        logger.info("Entering parking mode")
        self.state.mode = 'PARKING'
        self.state.led_state = 'PARKING'

        # Optionally disable Wi-Fi to save power
        opts = self.state.config.get_parking_opts()
        if not opts['wifi_in_parking']:
            try:
                import subprocess
                subprocess.run(['systemctl', 'stop', 'hostapd'],
                             capture_output=True, timeout=10)
                logger.info("Wi-Fi AP disabled for parking power savings")
            except Exception as e:
                logger.warning(f"Could not stop hostapd: {e}")

    def exit_parking(self):
        logger.info("Exiting parking mode")
        self.state.mode = 'RECORDING'
        self.state.led_state = 'RECORDING'
        self.state.recording = True
        self.last_movement_time = time.time()

        # Re-enable Wi-Fi if it was disabled
        opts = self.state.config.get_parking_opts()
        if not opts['wifi_in_parking']:
            try:
                import subprocess
                subprocess.run(['systemctl', 'start', 'hostapd'],
                             capture_output=True, timeout=10)
                logger.info("Wi-Fi AP re-enabled")
            except Exception as e:
                logger.warning(f"Could not start hostapd: {e}")

    def stop(self):
        self._stop_flag = True