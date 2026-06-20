#!/usr/bin/env python3
"""
LED Worker - Controls the status LED via GPIO using libgpiod.
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
        self.brightness = state.config.get_led_opts()['brightness']

    def run(self):
        # Try to import gpiod
        try:
            import gpiod
            self.has_gpio = True
            logger.info("LED worker started with GPIO access")
        except ImportError:
            self.has_gpio = False
            logger.warning("gpiod not available - LED worker in stub mode")

        last_state = None
        while not self._stop_flag:
            current_state = self.state.led_state

            if current_state != last_state:
                logger.info(f"LED state: {current_state}")
                last_state = current_state

            self.apply_pattern(current_state)

    def apply_pattern(self, state):
        """Apply LED pattern based on state."""
        if state == 'RECORDING':
            self.set_led(True)
            time.sleep(1)
        elif state == 'PARKING':
            self.set_led(True)
            time.sleep(1)
            self.set_led(False)
            time.sleep(3)
        elif state == 'EVENT_FLASH':
            for _ in range(5):
                self.set_led(True)
                time.sleep(0.1)
                self.set_led(False)
                time.sleep(0.1)
        elif state == 'ERROR':
            self.set_led(True)  # Solid on (red in hardware)
            time.sleep(1)
        elif state == 'FW_UPDATE':
            self.set_led(True)
            time.sleep(0.5)
            self.set_led(False)
            time.sleep(0.5)
        else:
            self.set_led(False)
            time.sleep(1)

    def set_led(self, on):
        """Set LED on or off via GPIO."""
        if not self.has_gpio:
            return
        # GPIO pin TBD from Bee-Internals pinout
        # This will be configured based on the actual GPIO pin used
        pass

    def stop(self):
        self._stop_flag = True
        self.set_led(False)