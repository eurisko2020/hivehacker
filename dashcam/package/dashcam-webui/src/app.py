#!/usr/bin/env python3
"""
Dashcam Web UI - Flask application
Serves file browser, live preview, settings, events, and system controls.
"""

import os
import json
import subprocess
import shutil
from pathlib import Path
from datetime import datetime
from flask import Flask, render_template, jsonify, send_file, request, redirect, url_for, Response

app = Flask(__name__, template_folder='templates', static_folder='static')

RECORDINGS_DIR = Path('/mnt/data/recordings')
META_DIR = RECORDINGS_DIR / '.meta'
LOCKED_DIR = RECORDINGS_DIR / 'LOCKED'
EVENTS_DIR = Path('/mnt/data/events')
CONFIG_PATH = '/etc/dashcamd.conf'
CONFIG_OVERRIDE = '/mnt/data/config/dashcamd.conf'


@app.route('/')
def index():
    """Dashboard home page with system status."""
    status = get_system_status()
    return render_template('index.html', status=status)


@app.route('/recordings')
def recordings():
    """File browser page."""
    files = list_recordings()
    return render_template('recordings.html', files=files)


@app.route('/settings')
def settings():
    """Settings page."""
    config = read_config()
    return render_template('settings.html', config=config)


@app.route('/events')
def events():
    """Events log page."""
    events_list = read_events()
    return render_template('events.html', events=events_list)


@app.route('/stream')
def stream():
    """Live MJPEG preview stream from libcamera-vid."""
    def generate():
        proc = subprocess.Popen(
            ['libcamera-vid', '-t', '0', '--codec', 'mjpeg',
             '--width', '1280', '--height', '720', '--framerate', '15', '-o', '-'],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
        )
        try:
            while True:
                chunk = proc.stdout.read(1024)
                if not chunk:
                    break
                yield chunk
        finally:
            proc.terminate()
    return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')


# === API ENDPOINTS ===

@app.route('/api/status')
def api_status():
    return jsonify(get_system_status())


@app.route('/api/recordings')
def api_recordings():
    page = int(request.args.get('page', 1))
    per_page = int(request.args.get('per_page', 50))
    filter_type = request.args.get('filter', 'all')
    files = list_recordings(filter_type)
    total = len(files)
    start = (page - 1) * per_page
    end = start + per_page
    return jsonify({
        'files': files[start:end],
        'total': total,
        'page': page,
        'per_page': per_page
    })


@app.route('/api/recordings/<filename>')
def api_download_recording(filename):
    filepath = RECORDINGS_DIR / filename
    if not filepath.exists():
        return jsonify({'error': 'File not found'}), 404
    return send_file(str(filepath), as_attachment=True)


@app.route('/api/recordings/<filename>/meta')
def api_recording_meta(filename):
    meta_name = filename.replace('.mp4', '.json')
    meta_path = META_DIR / meta_name
    if meta_path.exists():
        with open(meta_path) as f:
            return jsonify(json.load(f))
    return jsonify({'error': 'No metadata'}), 404


@app.route('/api/recordings/<filename>/lock', methods=['POST'])
def api_lock_recording(filename):
    locked_path = LOCKED_DIR / filename
    src_path = RECORDINGS_DIR / filename
    if not src_path.exists():
        return jsonify({'error': 'File not found'}), 404
    LOCKED_DIR.mkdir(exist_ok=True)
    if not locked_path.exists():
        os.link(str(src_path), str(locked_path))
    return jsonify({'status': 'locked'})


@app.route('/api/recordings/<filename>/unlock', methods=['POST'])
def api_unlock_recording(filename):
    locked_path = LOCKED_DIR / filename
    if locked_path.exists():
        locked_path.unlink()
    return jsonify({'status': 'unlocked'})


@app.route('/api/recordings/<filename>', methods=['DELETE'])
def api_delete_recording(filename):
    locked_path = LOCKED_DIR / filename
    if locked_path.exists():
        return jsonify({'error': 'File is locked'}), 403
    filepath = RECORDINGS_DIR / filename
    if filepath.exists():
        filepath.unlink()
        # Also delete metadata
        meta_path = META_DIR / filename.replace('.mp4', '.json')
        if meta_path.exists():
            meta_path.unlink()
        return jsonify({'status': 'deleted'})
    return jsonify({'error': 'File not found'}), 404


@app.route('/api/settings', methods=['GET', 'POST'])
def api_settings():
    if request.method == 'GET':
        return jsonify(read_config())
    elif request.method == 'POST':
        data = request.json
        write_config_override(data)
        return jsonify({'status': 'saved'})


@app.route('/api/events')
def api_events():
    return jsonify(read_events())


@app.route('/api/events/export')
def api_events_export():
    events_list = read_events()
    csv = 'timestamp,g_force,type,segment\n'
    for e in events_list:
        csv += f"{e.get('timestamp','')},{e.get('g_force','')},{e.get('type','')},{e.get('segment','')}\n"
    return Response(csv, mimetype='text/csv',
                    headers={'Content-Disposition': 'attachment; filename=events.csv'})


@app.route('/api/system/reboot', methods=['POST'])
def api_reboot():
    subprocess.run(['reboot'], capture_output=True)
    return jsonify({'status': 'rebooting'})


@app.route('/api/system/shutdown', methods=['POST'])
def api_shutdown():
    subprocess.run(['shutdown', '-h', 'now'], capture_output=True)
    return jsonify({'status': 'shutting down'})


@app.route('/api/system/factory-reset', methods=['POST'])
def api_factory_reset():
    # Wipe data partition
    for item in Path('/mnt/data').iterdir():
        if item.is_dir():
            shutil.rmtree(item)
        else:
            item.unlink()
    subprocess.run(['reboot'], capture_output=True)
    return jsonify({'status': 'reset complete, rebooting'})


@app.route('/api/system/diagnostics')
def api_diagnostics():
    """Download diagnostic logs as tar.gz."""
    import tempfile
    tmp = tempfile.NamedTemporaryFile(suffix='.tar.gz', delete=False)
    tmp.close()
    subprocess.run(['tar', 'czf', tmp.name,
                    '/mnt/data/logs/', '/var/log/',
                    '/opt/dashcam/bin/'], capture_output=True)
    return send_file(tmp.name, as_attachment=True,
                     download_name='diagnostics.tar.gz')


# === HELPER FUNCTIONS ===

def get_system_status():
    """Gather system status for dashboard."""
    # Storage
    try:
        stat = os.statvfs('/mnt/data')
        total = stat.f_blocks * stat.f_frsize
        free = stat.f_bavail * stat.f_frsize
        used = total - free
        storage_pct = (used / total) * 100 if total > 0 else 0
    except Exception:
        total = free = used = 0
        storage_pct = 0

    # CPU temp
    try:
        with open('/sys/class/thermal/thermal_zone0/temp') as f:
            cpu_temp = float(f.read().strip()) / 1000.0
    except Exception:
        cpu_temp = 0

    # Uptime
    try:
        with open('/proc/uptime') as f:
            uptime = float(f.read().split()[0])
    except Exception:
        uptime = 0

    # Count recordings and locked files
    recordings_count = len(list(RECORDINGS_DIR.glob('*.mp4')))
    locked_count = len(list(LOCKED_DIR.glob('*.mp4'))) if LOCKED_DIR.exists() else 0

    # Wi-Fi clients
    try:
        result = subprocess.run(['iw', 'dev', 'wlan0', 'station', 'dump'],
                              capture_output=True, text=True, timeout=5)
        wifi_clients = result.stdout.count('Station')
    except Exception:
        wifi_clients = 0

    return {
        'mode': 'RECORDING',  # Would read from dashcamd state
        'recording': True,
        'storage': {
            'total_gb': round(total / 1e9, 2),
            'used_gb': round(used / 1e9, 2),
            'free_gb': round(free / 1e9, 2),
            'percentage': round(storage_pct, 1),
        },
        'cpu_temp': round(cpu_temp, 1),
        'uptime_seconds': round(uptime),
        'recordings_count': recordings_count,
        'locked_count': locked_count,
        'wifi_clients': wifi_clients,
        'gps': {'fix': False, 'sats': 0, 'speed': 0},  # Would read from dashcamd
    }


def list_recordings(filter_type='all'):
    """List recording files with metadata."""
    files = []
    for f in sorted(RECORDINGS_DIR.glob('*.mp4'), reverse=True):
        is_locked = (LOCKED_DIR / f.name).exists() if LOCKED_DIR.exists() else False

        if filter_type == 'locked' and not is_locked:
            continue
        elif filter_type == 'unlocked' and is_locked:
            continue

        stat = f.stat()
        # Read metadata for duration
        duration = 0
        meta_path = META_DIR / f.name.replace('.mp4', '.json')
        if meta_path.exists():
            try:
                with open(meta_path) as mf:
                    meta = json.load(mf)
                    duration = meta.get('duration_s', 0)
            except Exception:
                pass

        files.append({
            'name': f.name,
            'size': stat.st_size,
            'size_mb': round(stat.st_size / 1048576, 1),
            'date': datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d %H:%M:%S'),
            'locked': is_locked,
            'duration': round(duration),
            'has_meta': meta_path.exists(),
        })
    return files


def read_events():
    """Read events from the events log."""
    events = []
    log_path = EVENTS_DIR / 'events.log'
    if log_path.exists():
        with open(log_path) as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        events.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue
    return events


def read_config():
    """Read dashcamd configuration."""
    import configparser
    parser = configparser.ConfigParser()
    parser.read(CONFIG_PATH)
    if os.path.exists(CONFIG_OVERRIDE):
        parser.read(CONFIG_OVERRIDE)

    # Also check for generated SSID file (set by generate-ssid.sh at boot)
    generated_ssid_path = '/mnt/data/config/generated_ssid.txt'
    if os.path.exists(generated_ssid_path):
        with open(generated_ssid_path) as f:
            generated_ssid = f.read().strip()
        if generated_ssid:
            if not parser.has_section('wifi'):
                parser.add_section('wifi')
            parser.set('wifi', 'ssid', generated_ssid)

    generated_pw_path = '/mnt/data/config/generated_password.txt'
    if os.path.exists(generated_pw_path):
        with open(generated_pw_path) as f:
            generated_pw = f.read().strip()
        if generated_pw:
            if not parser.has_section('wifi'):
                parser.add_section('wifi')
            parser.set('wifi', 'password', generated_pw)

    config = {}
    for section in parser.sections():
        config[section] = dict(parser.items(section))
    return config


def write_config_override(new_config):
    """Write configuration overrides."""
    import configparser
    parser = configparser.ConfigParser()
    parser.read(CONFIG_PATH)

    for section, values in new_config.items():
        if not parser.has_section(section):
            parser.add_section(section)
        for key, val in values.items():
            parser.set(section, key, str(val))

    Path('/mnt/data/config').mkdir(parents=True, exist_ok=True)
    with open(CONFIG_OVERRIDE, 'w') as f:
        parser.write(f)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=False)