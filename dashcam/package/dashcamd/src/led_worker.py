#!/usr/bin/env python3
"""
LED Worker — Controls 3 physical LEDs on the HDC via GPIO:
  - Power LED: solid on when device is powered
  - GPS LED: solid when GPS has fix, off when no fix, blinking when searching
  - REC LED: blinks red while recording, solid red on event, off when stopped

GPIO pins are configurable in dashcamd.conf [led] section.
Default pins are based on HDC hardware (to be confirmed via GPIO probe).
"""

import time
import logging
import threading

logger = logging.getLogger('dashcamd.led')


class LEDWorker(threading.Thread):
    def __init__(self, state):
        super().__init__(daemon=True)
        self.state = state
        self._stop_flag = False
        self.brightness = state.config.get_led_opts().get('brightness', 255)
        self.led_enabled = True

        # GPIO pins for the 3 LEDs (configurable)
        # These defaults are guesses — will be confirmed by probing the device
        self.POWER_GPIO = state.config.get('led', 'power_gpio', 26)  # Power LED
        self.GPS_GPIO = state.config.get('led', 'gps_gpio', 13)     # GPS LED
        self.REC_GPIO = state.config.get('led', 'rec_gpio', 12)     # REC LED

        # GPIO chip
        self.chip = None
        self.power_line = None
        self.gps_line = None
        self.rec_line = None

    def init_gpio(self):
        """Initialize GPIO lines for the 3 LEDs."""
        try:
            import gpiod
            self.chip = gpiod.Chip('gpiochip0')
            self.power_line = self.chip.get_line(self.POWER_GPIO)
            self.gps_line = self.chip.get_line(self.GPS_GPIO)
            self.rec_line = self.chip.get_line(self.REC_GPIO)
            self.power_line.request(consumer='hivehacker-power', type=gpiod.LINE_REQ_DIR_OUT)
            self.gps_line.request(consumer='hivehacker-gps', type=gpiod.LINE_REQ_DIR_OUT)
            self.rec_line.request(consumer='hivehacker-rec', type=gpiod.LINE_REQ_DIR_OUT)
            logger.info(f"GPIO initialized: Power={self.POWER_GPIO}, GPS={self.GPS_GPIO}, REC={self.REC_GPIO}")
            return True
        except Exception as e:
            logger.warning(f"GPIO init failed: {e} — LEDs will run in stub mode")
            return False

    def run(self):
        has_gpio = self.init_gpio()

        # Power LED is always on
        self.set_led('power', True)

        while not self._stop_flag:
            if not self.led_enabled:
                self.set_led('rec', False)
                self.set_led('gps', False)
                time.sleep(1)
                continue

            current_state = self.state.led_state
            gps_fix = self.state.gps_data.get('last_fix') is not None

            # GPS LED: solid if fix, blink if searching
            if gps_fix:
                self.set_led('gps', True)
            else:
                self.set_led('gps', True)
                time.sleep(0.5)
                self.set_led('gps', False)
                time.sleep(0.5)

            # REC LED based on state
            if current_state == 'RECORDING' and self.state.recording:
                # Blink red while recording: 0.5s on, 0.5s off
                self.set_led('rec', True)
                time.sleep(0.5)
                self.set_led('rec', False)
                time.sleep(0.5)
            elif current_state == 'EVENT_FLASH':
                # Rapid flash on event (5 seconds)
                for _ in range(10):
                    self.set_led('rec', True)
                    time.sleep(0.1)
                    self.set_led('rec', False)
                    time.sleep(0.1)
            elif current_state == 'PARKING':
                # Slow pulse in parking mode
                self.set_led('rec', True)
                time.sleep(1)
                self.set_led('rec', False)
                time.sleep(3)
            elif current_state == 'ERROR':
                # Solid red on error
                self.set_led('rec', True)
                time.sleep(1)
            else:
                self.set_led('rec', False)
                time.sleep(1)

    def set_led(self, led_name, on):
        """Set a specific LED on or off."""
        if not self.chip:
            return  # Stub mode
        try:
            import gpiod
            val = 1 if on else 0
            if led_name == 'power' and self.power_line:
                self.power_line.set_value(val)
            elif led_name == 'gps' and self.gps_line:
                self.gps_line.set_value(val)
            elif led_name == 'rec' and self.rec_line:
                self.rec_line.set_value(val)
        except Exception as e:
            logger.debug(f"LED set error ({led_name}): {e}")

    def stop(self):
        self._stop_flag = True
        # Turn off REC and GPS LEDs, keep power on
        self.set_led('rec', False)
        self.set_led('gps', False)