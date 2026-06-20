#!/usr/bin/env python3
"""
IMU Worker - Reads accelerometer data via I2C and detects impact events.
Triggers segment locking on G-sensor events.
"""

import time
import math
import json
import logging
import threading
import collections
from pathlib import Path
from datetime import datetime, timezone

logger = logging.getLogger('dashcamd.imu')


class IMUWorker(threading.Thread):
    def __init__(self, state):
        super().__init__(daemon=True)
        self.state = state
        self._stop_flag = False
        self.ring_buffer = collections.deque(maxlen=1500)  # 30s at 50Hz

    def run(self):
        opts = self.state.config.get_imu_opts()
        sample_interval = 1.0 / opts['sample_rate']
        threshold = opts['accel_threshold']
        debounce_s = opts['debounce_ms'] / 1000.0
        last_event_time = 0

        while not self._stop_flag:
            try:
                ax, ay, az = self.read_accel(opts['i2c_bus'], opts['i2c_addr'])
                if ax is None:
                    time.sleep(1)
                    continue

                # Calculate acceleration magnitude minus gravity
                magnitude = math.sqrt(ax**2 + ay**2 + az**2) - 1.0

                now = time.time()
                self.ring_buffer.append((now, magnitude))

                # Update shared state
                self.state.imu_data['current'] = {
                    'x': ax, 'y': ay, 'z': az, 'magnitude': magnitude
                }
                max_accel = self.state.imu_data.get('max_accel', 0)
                if abs(magnitude) > max_accel:
                    self.state.imu_data['max_accel'] = abs(magnitude)

                # Event detection with debounce
                if abs(magnitude) > threshold:
                    if now - last_event_time > debounce_s:
                        self.trigger_event(abs(magnitude), now)
                        last_event_time = now

                time.sleep(sample_interval)

            except Exception as e:
                logger.debug(f"IMU read error: {e}")
                time.sleep(1)

    def read_accel(self, bus_num, addr):
        """Read accelerometer data from I2C device.
        Supports MPU6050 (0x68) and LSM6DS3 (0x6A) - auto-detect."""
        try:
            import smbus
            bus = smbus.SMBus(bus_num)

            # Try MPU6050 first
            try:
                # Read accel registers 0x3B-0x40
                data = bus.read_i2c_block_data(addr, 0x3B, 6)
                ax = self._twos_complement(data[0] << 8 | data[1]) / 16384.0
                ay = self._twos_complement(data[2] << 8 | data[3]) / 16384.0
                az = self._twos_complement(data[4] << 8 | data[5]) / 16384.0
                return ax, ay, az
            except Exception:
                pass

            # Try LSM6DS3
            try:
                data = bus.read_i2c_block_data(0x6A, 0x28, 6)
                ax = self._twos_complement(data[0] << 8 | data[1]) / 0.061 / 1000.0
                ay = self._twos_complement(data[2] << 8 | data[3]) / 0.061 / 1000.0
                az = self._twos_complement(data[4] << 8 | data[5]) / 0.061 / 1000.0
                return ax, ay, az
            except Exception:
                pass

            return None, None, None

        except Exception:
            return None, None, None

    @staticmethod
    def _twos_complement(val):
        """Convert 16-bit two's complement to signed value."""
        if val >= 0x8000:
            return val - 0x10000
        return val

    def trigger_event(self, g_force, timestamp):
        """Handle an impact event - lock segments and log."""
        logger.warning(f"EVENT DETECTED: {g_force:.2f}G at {timestamp}")

        # Lock current segment
        current = self.state.current_segment
        if current:
            self._lock_segment(current)

        # Log event
        event = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'g_force': round(g_force, 3),
            'type': 'impact',
            'segment': current
        }
        self.state.events.append(event)

        # Write to events log file
        events_dir = Path('/mnt/data/events')
        events_dir.mkdir(parents=True, exist_ok=True)
        with open(events_dir / 'events.log', 'a') as f:
            f.write(json.dumps(event) + '\n')

        # Set LED to event flash
        self.state.led_state = 'EVENT_FLASH'
        threading.Timer(5.0, self._reset_led).start()

    def _lock_segment(self, segment_name):
        """Lock the current segment using the storage worker's method."""
        # We need to call the storage worker's lock method
        # Since workers are separate threads, we use a simple approach
        try:
            recordings = Path('/mnt/data/recordings')
            locked_dir = recordings / 'LOCKED'
            locked_dir.mkdir(exist_ok=True)

            src = recordings / f"{segment_name}.mp4"
            if not src.exists():
                src = recordings / f"{segment_name}.h264"
            if src.exists():
                dst = locked_dir / src.name
                if not dst.exists():
                    os.link(str(src), str(dst))
                    self.state.locked_files.add(src.name)
                    logger.info(f"Segment locked: {src.name}")
        except Exception as e:
            logger.error(f"Failed to lock segment: {e}")

    def _reset_led(self):
        """Reset LED to recording state after event flash."""
        if self.state.mode == 'RECORDING':
            self.state.led_state = 'RECORDING'
        elif self.state.mode == 'PARKING':
            self.state.led_state = 'PARKING'

    def stop(self):
        self._stop_flag = True