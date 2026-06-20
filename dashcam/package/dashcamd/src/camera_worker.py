#!/usr/bin/env python3
"""
Camera Worker - Records H.264/HEVC video via libcamera-vid + V4L2 hardware encoder.
Replaces the stock camera-bridge JPEG frame pipeline.
"""

import os
import time
import json
import subprocess
import threading
import logging
from pathlib import Path
from datetime import datetime, timezone

logger = logging.getLogger('dashcamd.camera')


class CameraWorker(threading.Thread):
    def __init__(self, state):
        super().__init__(daemon=True)
        self.state = state
        self._stop_flag = False
        self.proc = None
        self.segment_start = None
        self.current_segment_name = None

    def run(self):
        opts = self.state.config.get_camera_opts()
        storage_opts = self.state.config.get_storage_opts()

        while not self._stop_flag:
            if not self.state.recording:
                time.sleep(1)
                continue

            try:
                self.start_segment(opts, storage_opts)
                self.wait_for_segment_duration(opts, storage_opts)
                self.close_segment(storage_opts)
            except Exception as e:
                logger.error(f"Camera pipeline error: {e}")
                self.state.mode = 'ERROR'
                time.sleep(5)  # Backoff before retry
                self.state.mode = 'RECORDING'

    def start_segment(self, opts, storage_opts):
        """Start a new recording segment using libcamera-vid."""
        timestamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
        temp_name = f"{storage_opts['path']}/.tmp_{timestamp}.h264"
        self.current_segment_name = timestamp
        self.segment_start = time.time()

        # Build libcamera-vid command
        codec = opts['codec']
        cmd = [
            'libcamera-vid',
            '-t', '0',  # Run indefinitely
            '--width', str(opts['width']),
            '--height', str(opts['height']),
            '--framerate', str(opts['framerate']),
            '--codec', codec,
            '--bitrate', str(opts['bitrate']),
            '--inline',
            '--segment', '1',  # We manage segments ourselves
            '-o', temp_name
        ]

        if codec == 'h264':
            cmd.extend(['--profile', opts['profile']])

        logger.info(f"Starting segment: {timestamp}")
        logger.debug(f"Command: {' '.join(cmd)}")

        self.proc = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE
        )
        self.state.current_segment = timestamp

    def wait_for_segment_duration(self, opts, storage_opts):
        """Wait until segment duration is reached, then stop libcamera-vid."""
        duration = opts['segment_duration']
        while not self._stop_flag and self.state.recording:
            elapsed = time.time() - self.segment_start
            if elapsed >= duration:
                break
            time.sleep(1)

    def close_segment(self, storage_opts):
        """Stop libcamera-vid and remux H.264 to MP4."""
        if self.proc:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self.proc.kill()
                self.proc.wait()

            # Read any stderr for debugging
            stderr = self.proc.stderr.read().decode() if self.proc.stderr else ''
            if stderr:
                logger.debug(f"libcamera-vid stderr: {stderr[:500]}")

        timestamp = self.current_segment_name
        temp_name = f"{storage_opts['path']}/.tmp_{timestamp}.h264"
        final_name = f"{storage_opts['path']}/{timestamp}.mp4"

        if not os.path.exists(temp_name) or os.path.getsize(temp_name) == 0:
            logger.warning(f"Empty segment: {temp_name}")
            return

        # Remux H.264 elementary stream to MP4 with faststart
        try:
            result = subprocess.run(
                ['ffmpeg', '-y', '-i', temp_name, '-c', 'copy',
                 '-movflags', '+faststart', final_name],
                capture_output=True, timeout=60
            )
            if result.returncode == 0:
                logger.info(f"Segment complete: {timestamp}.mp4 "
                          f"({os.path.getsize(final_name) / 1048576:.1f} MB)")
                os.unlink(temp_name)

                # Write metadata sidecar
                if storage_opts['metadata']:
                    self.write_metadata(timestamp, final_name, storage_opts)
            else:
                logger.error(f"ffmpeg remux failed: {result.stderr.decode()[:300]}")
                # Keep the raw H.264 file as fallback
                os.rename(temp_name, f"{storage_opts['path']}/{timestamp}.h264")
        except Exception as e:
            logger.error(f"Segment finalization error: {e}")

    def write_metadata(self, timestamp, mp4_path, storage_opts):
        """Write JSON sidecar with GPS/IMU data for this segment."""
        meta_path = f"{storage_opts['path']}/.meta/{timestamp}.json"
        meta = {
            'filename': os.path.basename(mp4_path),
            'timestamp': timestamp,
            'duration_s': time.time() - self.segment_start if self.segment_start else 0,
            'size_bytes': os.path.getsize(mp4_path),
            'gps_track': list(self.state.gps_data.get('track', [])),
            'imu_summary': {
                'max_accel': self.state.imu_data.get('max_accel', 0),
                'events': [e for e in self.state.events
                          if e.get('segment') == timestamp]
            }
        }
        with open(meta_path, 'w') as f:
            json.dump(meta, f, indent=2)

    def stop(self):
        self._stop_flag = True
        if self.proc:
            try:
                self.proc.terminate()
                self.proc.wait(timeout=10)
            except Exception:
                pass