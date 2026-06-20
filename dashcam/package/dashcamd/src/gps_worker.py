#!/usr/bin/env python3
"""
GPS Worker - Reads NMEA sentences from GPS module and stores track data.
"""

import time
import json
import logging
import threading

logger = logging.getLogger('dashcamd.gps')

try:
    import serial
    HAS_SERIAL = True
except ImportError:
    HAS_SERIAL = False
    logger.warning("pyserial not available - GPS worker will run in stub mode")


class GPSWorker(threading.Thread):
    def __init__(self, state):
        super().__init__(daemon=True)
        self.state = state
        self._stop_flag = False
        self.serial_conn = None

    def run(self):
        opts = self.state.config.get_gps_opts()

        if not HAS_SERIAL:
            logger.warning("Running in stub mode (no pyserial)")
            while not self._stop_flag:
                time.sleep(5)
            return

        while not self._stop_flag:
            try:
                self.serial_conn = serial.Serial(
                    opts['serial'], opts['baud'], timeout=1
                )
                logger.info(f"GPS connected on {opts['serial']} @ {opts['baud']} baud")
                self.read_loop()
            except Exception as e:
                logger.warning(f"GPS connection error: {e}")
                time.sleep(10)  # Retry delay

    def read_loop(self):
        track = []
        while not self._stop_flag and self.serial_conn:
            try:
                line = self.serial_conn.readline().decode('ascii', errors='replace').strip()
                if not line or not line.startswith('$'):
                    continue

                if 'GGA' in line:
                    data = self.parse_gga(line)
                    if data:
                        track.append({
                            'ts': time.time(),
                            'lat': data['lat'],
                            'lon': data['lon'],
                            'alt': data['alt'],
                            'sats': data['sats']
                        })

                elif 'RMC' in line:
                    data = self.parse_rmc(line)
                    if data:
                        track.append({
                            'ts': time.time(),
                            'speed_kmh': data['speed_kmh'],
                            'heading': data['heading']
                        })

                # Keep last 100 points in shared state
                self.state.gps_data['track'] = track[-100:]
                if track:
                    self.state.gps_data['last_fix'] = track[-1]

            except Exception as e:
                logger.debug(f"NMEA parse error: {e}")

    def parse_gga(self, line):
        """Parse $GPGGA or $GNGGA sentence."""
        try:
            parts = line.split(',')
            if len(parts) < 15:
                return None
            if parts[6] == '0':  # No fix
                return None

            lat_raw = parts[2]
            lat_dir = parts[3]
            lon_raw = parts[4]
            lon_dir = parts[5]

            lat = self.nmea_to_decimal(lat_raw, lat_dir)
            lon = self.nmea_to_decimal(lon_raw, lon_dir)
            alt = float(parts[9]) if parts[9] else 0
            sats = int(parts[7]) if parts[7] else 0

            return {'lat': lat, 'lon': lon, 'alt': alt, 'sats': sats}
        except Exception:
            return None

    def parse_rmc(self, line):
        """Parse $GPRMC or $GNRMC sentence."""
        try:
            parts = line.split(',')
            if len(parts) < 12:
                return None
            if parts[2] != 'A':  # Not valid
                return None

            speed_knots = float(parts[7]) if parts[7] else 0
            heading = float(parts[8]) if parts[8] else 0

            return {
                'speed_kmh': speed_knots * 1.852,
                'heading': heading
            }
        except Exception:
            return None

    @staticmethod
    def nmea_to_decimal(raw, direction):
        """Convert NMEA coordinate to decimal degrees."""
        if not raw:
            return 0
        if direction in ('N', 'S'):
            deg = int(raw[:2])
            minutes = float(raw[2:])
        else:
            deg = int(raw[:3])
            minutes = float(raw[3:])
        decimal = deg + minutes / 60
        if direction in ('S', 'W'):
            decimal = -decimal
        return round(decimal, 6)

    def stop(self):
        self._stop_flag = True
        if self.serial_conn:
            try:
                self.serial_conn.close()
            except Exception:
                pass