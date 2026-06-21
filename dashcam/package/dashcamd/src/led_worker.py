#!/usr/bin/env python3
"""
LED Worker — Controls 3 physical LEDs on the HDC via IS31FL3199 I2C controller.

The HDC hardware uses an IS31FL3199 RGB LED controller chip on I2C bus 1,
address 0x64. The stock Hivemapper firmware runs a C++ "led-controller" binary
that watches /tmp/led.json for changes and writes to the chip over I2C.

We use the same /tmp/led.json interface so the stock led-controller binary
handles the actual I2C communication. This worker writes the JSON file and
manages the LED state patterns.

LED index mapping (from IS31FL3199 register layout):
  0 = Power LED
  1 = GPS LED
  2 = REC LED

JSON format for /tmp/led.json:
  {"leds": [
    {"index": 0, "red": R, "blue": B, "green": G, "on": true/false},
    {"index": 1, "red": R, "blue": B, "green": G, "on": true/false},
    {"index": 2, "red": R, "blue": B, "green": G, "on": true/false}
  ]}

Per-LED enable/disable is supported via config. When a LED is disabled in
config, it stays off regardless of state.
"""

import json
import os
import time
import logging
import threading

logger = logging.getLogger('dashcamd.led')

LED_JSON_PATH = '/tmp/led.json'

# LED indices on the IS31FL3199
POWER_LED = 0
GPS_LED = 1
REC_LED = 2

# Default colors (RGB 0-255)
POWER_COLOR = {'red': 0, 'blue': 255, 'green': 0}    # Blue (power on)
GPS_COLOR = {'red': 0, 'blue': 100, 'green': 255}    # Cyan-ish (GPS)
REC_COLOR = {'red': 255, 'blue': 0, 'green': 0}      # Red (recording)
ERROR_COLOR = {'red': 255, 'blue': 0, 'green': 0}     # Red (error)
EVENT_COLOR = {'red': 255, 'blue': 0, 'green': 0}     # Red (event)
PARKING_COLOR = {'red': 0, 'blue': 0, 'green': 255}   # Green (parking)


class LEDWorker(threading.Thread):
    def __init__(self, state):
        super().__init__(daemon=True)
        self.state = state
        self._stop_flag = False

        # Per-LED enable/disable (read from config)
        self.led_enabled = {
            POWER_LED: state.config.getboolean('led', 'power_enabled', True),
            GPS_LED: state.config.getboolean('led', 'gps_enabled', True),
            REC_LED: state.config.getboolean('led', 'rec_enabled', True),
        }

        # Current LED state cache
        self._current_json = None

    def write_led_json(self, leds):
        """Write LED state to /tmp/led.json for the led-controller binary to pick up.

        Args:
            leds: list of dicts with keys: index, red, blue, green, on
        """
        data = {'leds': leds}
        try:
            # Write atomically: write to temp file then rename
            tmp_path = LED_JSON_PATH + '.tmp'
            with open(tmp_path, 'w') as f:
                json.dump(data, f)
            os.rename(tmp_path, LED_JSON_PATH)
            self._current_json = data
        except Exception as e:
            logger.warning(f"Failed to write LED JSON: {e}")

    def set_led(self, index, color, on):
        """Set a single LED's color and on/off state."""
        if not self.led_enabled.get(index, True):
            color = {'red': 0, 'blue': 0, 'green': 0}
            on = False

        led = {
            'index': index,
            'red': color.get('red', 0),
            'blue': color.get('blue', 0),
            'green': color.get('green', 0),
            'on': on,
        }

        # Build full LED list (preserve other LEDs' current state)
        all_leds = []
        for i in range(3):
            if i == index:
                all_leds.append(led)
            elif self._current_json and i < len(self._current_json.get('leds', [])):
                all_leds.append(self._current_json['leds'][i])
            else:
                all_leds.append({
                    'index': i,
                    'red': 0,
                    'blue': 0,
                    'green': 0,
                    'on': False,
                })

        self.write_led_json(all_leds)

    def set_all_leds(self, power_on, gps_on, rec_on, rec_color=None, gps_color=None):
        """Set all 3 LEDs at once."""
        leds = []
        for index, on, color in [
            (POWER_LED, power_on, POWER_COLOR),
            (GPS_LED, gps_on, gps_color or GPS_COLOR),
            (REC_LED, rec_on, rec_color or REC_COLOR),
        ]:
            if not self.led_enabled.get(index, True):
                leds.append({'index': index, 'red': 0, 'blue': 0, 'green': 0, 'on': False})
            else:
                leds.append({
                    'index': index,
                    'red': color.get('red', 0),
                    'blue': color.get('blue', 0),
                    'green': color.get('green', 0),
                    'on': on,
                })
        self.write_led_json(leds)

    def run(self):
        logger.info("LED worker started (IS31FL3199 via /tmp/led.json)")

        # Power LED on immediately
        self.set_all_leds(power_on=True, gps_on=False, rec_on=False)

        while not self._stop_flag:
            current_state = self.state.led_state
            gps_fix = self.state.gps_data.get('last_fix') is not None

            # Power LED is always on (if enabled)
            power_on = True

            # GPS LED: solid if fix, blink if searching
            if gps_fix:
                gps_on = True
            else:
                gps_on = True
                self.set_all_leds(power_on=power_on, gps_on=True, rec_on=self._rec_on(current_state), rec_color=self._rec_color(current_state))
                time.sleep(0.5)
                self.set_all_leds(power_on=power_on, gps_on=False, rec_on=self._rec_on(current_state), rec_color=self._rec_color(current_state))
                time.sleep(0.5)
                continue

            # REC LED based on state
            if current_state == 'RECORDING' and self.state.recording:
                # Blink red while recording: 0.5s on, 0.5s off
                self.set_all_leds(power_on=power_on, gps_on=True, rec_on=True, rec_color=REC_COLOR)
                time.sleep(0.5)
                self.set_all_leds(power_on=power_on, gps_on=True, rec_on=False)
                time.sleep(0.5)
            elif current_state == 'EVENT_FLASH':
                # Rapid flash on event (5 seconds)
                for _ in range(10):
                    if self._stop_flag:
                        break
                    self.set_all_leds(power_on=power_on, gps_on=True, rec_on=True, rec_color=EVENT_COLOR)
                    time.sleep(0.1)
                    self.set_all_leds(power_on=power_on, gps_on=True, rec_on=False)
                    time.sleep(0.1)
            elif current_state == 'PARKING':
                # Slow pulse in parking mode
                self.set_all_leds(power_on=power_on, gps_on=True, rec_on=True, rec_color=PARKING_COLOR)
                time.sleep(1)
                self.set_all_leds(power_on=power_on, gps_on=True, rec_on=False)
                time.sleep(3)
            elif current_state == 'ERROR':
                # Solid red on error
                self.set_all_leds(power_on=power_on, gps_on=True, rec_on=True, rec_color=ERROR_COLOR)
                time.sleep(1)
            else:
                self.set_all_leds(power_on=power_on, gps_on=True, rec_on=False)
                time.sleep(1)

    def _rec_on(self, state):
        """Whether REC LED should be on for this state."""
        if state in ('RECORDING', 'EVENT_FLASH', 'ERROR', 'PARKING'):
            return True
        return False

    def _rec_color(self, state):
        """REC LED color for this state."""
        if state == 'PARKING':
            return PARKING_COLOR
        if state == 'ERROR':
            return ERROR_COLOR
        return REC_COLOR

    def update_enabled(self, led_name, enabled):
        """Update per-LED enable/disable at runtime (called from web API)."""
        index_map = {'power': POWER_LED, 'gps': GPS_LED, 'rec': REC_LED}
        index = index_map.get(led_name)
        if index is not None:
            self.led_enabled[index] = enabled
            if not enabled:
                self.set_led(index, {'red': 0, 'blue': 0, 'green': 0}, False)
            logger.info(f"LED {led_name} (index {index}) {'enabled' if enabled else 'disabled'}")

    def stop(self):
        self._stop_flag = True
        # Turn off all LEDs except power
        self.set_all_leds(power_on=self.led_enabled.get(POWER_LED, True), gps_on=False, rec_on=False)