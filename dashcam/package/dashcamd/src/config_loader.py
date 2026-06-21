#!/usr/bin/env python3
"""Configuration loader for dashcamd - reads INI-style config with overrides."""

import os
import configparser
from pathlib import Path


class ConfigLoader:
    """Loads dashcamd.conf and allows runtime overrides from /mnt/data/config/."""

    def __init__(self, config_path='/etc/dashcamd.conf'):
        self.parser = configparser.ConfigParser()
        self.config_path = config_path
        self.override_path = '/mnt/data/config/dashcamd.conf'

        # Load base config
        if os.path.exists(config_path):
            self.parser.read(config_path)
        else:
            raise FileNotFoundError(f"Config file not found: {config_path}")

        # Apply overrides from data partition (if present)
        if os.path.exists(self.override_path):
            override = configparser.ConfigParser()
            override.read(self.override_path)
            for section in override.sections():
                if not self.parser.has_section(section):
                    self.parser.add_section(section)
                for key, val in override.items(section):
                    self.parser.set(section, key, val)

    def get(self, section, key, fallback=None):
        return self.parser.get(section, key, fallback=fallback)

    def getint(self, section, key, fallback=0):
        return self.parser.getint(section, key, fallback=fallback)

    def getfloat(self, section, key, fallback=0.0):
        return self.parser.getfloat(section, key, fallback=fallback)

    def getboolean(self, section, key, fallback=False):
        return self.parser.getboolean(section, key, fallback=fallback)

    def set(self, section, key, value):
        if not self.parser.has_section(section):
            self.parser.add_section(section)
        self.parser.set(section, key, str(value))

    def save_override(self):
        """Save current config as override to /mnt/data/config/dashcamd.conf."""
        Path('/mnt/data/config').mkdir(parents=True, exist_ok=True)
        with open(self.override_path, 'w') as f:
            self.parser.write(f)

    def get_camera_opts(self):
        """Return camera options as a dict."""
        return {
            'width': self.getint('camera', 'width', 1920),
            'height': self.getint('camera', 'height', 1080),
            'framerate': self.getint('camera', 'framerate', 30),
            'codec': self.get('camera', 'codec', 'h264'),
            'bitrate': self.getint('camera', 'bitrate', 10000000),
            'profile': self.get('camera', 'profile', 'high'),
            'segment_duration': self.getint('camera', 'segment_duration', 180),
            'intra_refresh': self.getint('camera', 'intra_refresh', 60),
        }

    def get_storage_opts(self):
        return {
            'path': self.get('storage', 'path', '/mnt/data/recordings'),
            'max_usage': self.getint('storage', 'max_usage', 85),
            'target_usage': self.getint('storage', 'target_usage', 80),
            'metadata': self.getboolean('storage', 'metadata', True),
        }

    def get_gps_opts(self):
        return {
            'serial': self.get('gps', 'serial', '/dev/ttyAMA0'),
            'baud': self.getint('gps', 'baud', 9600),
            'osd_overlay': self.getboolean('gps', 'osd_overlay', False),
            'osd_format': self.get('gps', 'osd_format', ''),
        }

    def get_imu_opts(self):
        return {
            'i2c_bus': self.getint('imu', 'i2c_bus', 1),
            'i2c_addr': self.getint('imu', 'i2c_addr', 0x68, ),
            'sample_rate': self.getint('imu', 'sample_rate', 50),
            'accel_threshold': self.getfloat('imu', 'accel_threshold', 0.8),
            'event_pre_buffer': self.getint('imu', 'event_pre_buffer', 30),
            'event_post_buffer': self.getint('imu', 'event_post_buffer', 60),
            'debounce_ms': self.getint('imu', 'debounce_ms', 50),
        }

    def get_parking_opts(self):
        return {
            'entry_timeout': self.getint('parking', 'entry_timeout', 300),
            'exit_on_movement': self.getboolean('parking', 'exit_on_movement', True),
            'wifi_in_parking': self.getboolean('parking', 'wifi_in_parking', True),
        }

    def get_led_opts(self):
        return {
            'i2c_bus': self.getint('led', 'i2c_bus', 1),
            'i2c_addr': self.getint('led', 'i2c_addr', 0x64),
            'power_enabled': self.getboolean('led', 'power_enabled', True),
            'gps_enabled': self.getboolean('led', 'gps_enabled', True),
            'rec_enabled': self.getboolean('led', 'rec_enabled', True),
        }

    def get_wifi_opts(self):
        return {
            'ssid': self.get('wifi', 'ssid', 'dashcam'),
            'password': self.get('wifi', 'password', 'dashcam123'),
            'channel': self.getint('wifi', 'channel', 6),
            'ip': self.get('wifi', 'ip', '192.168.0.10'),
            'dhcp_start': self.get('wifi', 'dhcp_start', '192.168.0.11'),
            'dhcp_end': self.get('wifi', 'dhcp_end', '192.168.0.50'),
        }