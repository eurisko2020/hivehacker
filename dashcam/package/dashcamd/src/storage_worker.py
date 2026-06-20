#!/usr/bin/env python3
"""
Storage Worker - Monitors disk usage and manages loop deletion.
Replaces the stock folder-purger.
"""

import os
import time
import shutil
import logging
import threading
from pathlib import Path

logger = logging.getLogger('dashcamd.storage')


class StorageWorker(threading.Thread):
    def __init__(self, state):
        super().__init__(daemon=True)
        self.state = state
        self._stop_flag = False

    def run(self):
        while not self._stop_flag:
            try:
                self.check_and_purge()
            except Exception as e:
                logger.error(f"Storage worker error: {e}")
            time.sleep(30)  # Check every 30 seconds

    def get_disk_usage(self, path):
        """Return disk usage percentage for the given path."""
        stat = os.statvfs(path)
        total = stat.f_blocks * stat.f_frsize
        free = stat.f_bavail * stat.f_frsize
        used = total - free
        return (used / total) * 100 if total > 0 else 0

    def list_unlocked_segments(self, recordings_path):
        """List all unlocked MP4 segments sorted oldest first."""
        segments = []
        locked_dir = Path(recordings_path) / 'LOCKED'

        for f in Path(recordings_path).glob('*.mp4'):
            # Skip if this file is locked (has a copy/link in LOCKED dir)
            locked_path = locked_dir / f.name
            if locked_path.exists():
                continue
            segments.append({
                'path': str(f),
                'name': f.name,
                'size': f.stat().st_size,
                'mtime': f.stat().st_mtime
            })

        segments.sort(key=lambda s: s['mtime'])
        return segments

    def check_and_purge(self):
        """Delete oldest unlocked segments if disk usage exceeds threshold."""
        opts = self.state.config.get_storage_opts()
        path = opts['path']
        max_usage = opts['max_usage']
        target = opts['target_usage']

        usage = self.get_disk_usage(path)
        self.state.storage_usage = usage

        if usage < max_usage:
            return

        logger.info(f"Storage at {usage:.1f}%, purging to {target}%...")
        segments = self.list_unlocked_segments(path)

        if not segments:
            logger.warning("No unlocked segments to delete! Storage full!")
            return

        while self.get_disk_usage(path) > target and segments:
            seg = segments.pop(0)
            try:
                os.unlink(seg['path'])
                logger.info(f"PURGED: {seg['name']} ({seg['size'] / 1048576:.1f} MB freed)")

                # Also delete metadata sidecar
                meta_path = Path(path) / '.meta' / (seg['name'].replace('.mp4', '.json'))
                if meta_path.exists():
                    meta_path.unlink()
            except Exception as e:
                logger.error(f"Failed to delete {seg['name']}: {e}")

    def lock_segment(self, segment_name):
        """Lock a segment by creating a hard link in the LOCKED directory."""
        opts = self.state.config.get_storage_opts()
        recordings = Path(opts['path'])
        locked_dir = recordings / 'LOCKED'
        locked_dir.mkdir(exist_ok=True)

        src = recordings / f"{segment_name}.mp4"
        if not src.exists():
            # Try with full name
            src = recordings / segment_name
            if not src.exists():
                return False

        dst = locked_dir / src.name
        if dst.exists():
            return True  # Already locked

        try:
            os.link(str(src), str(dst))
            self.state.locked_files.add(src.name)
            logger.info(f"LOCKED: {src.name}")
            return True
        except Exception as e:
            logger.error(f"Failed to lock {src.name}: {e}")
            return False

    def unlock_segment(self, segment_name):
        """Unlock a segment by removing the hard link from LOCKED directory."""
        opts = self.state.config.get_storage_opts()
        locked_dir = Path(opts['path']) / 'LOCKED'

        # Try both with .mp4 extension and raw name
        for name in [segment_name, f"{segment_name}.mp4"]:
            locked_file = locked_dir / name
            if locked_file.exists():
                try:
                    locked_file.unlink()
                    self.state.locked_files.discard(name)
                    logger.info(f"UNLOCKED: {name}")
                    return True
                except Exception as e:
                    logger.error(f"Failed to unlock {name}: {e}")
                    return False
        return False

    def stop(self):
        self._stop_flag = True