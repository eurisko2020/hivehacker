#!/usr/bin/env python3
"""
HiveHacker Dashcam Web UI — Flask application
Preview version for local testing (mock data, no real hardware needed)
"""

import os
import json
import random
import subprocess
from pathlib import Path
from datetime import datetime, timedelta
from flask import Flask, render_template, jsonify, send_file, request, Response, send_from_directory

app = Flask(__name__, template_folder='templates', static_folder='static')

# Mock state for preview
MOCK_RECORDINGS = []
for i in range(15):
    h = random.randint(14, 16)
    m = random.randint(0, 59)
    s = random.randint(0, 59)
    size = random.randint(40, 120)
    locked = random.random() < 0.2
    MOCK_RECORDINGS.append({
        'name': f'20260620_{h:02d}{m:02d}{s:02d}.mp4',
        'size': size * 1048576,
        'size_mb': size,
        'date': f'2026-06-20 {h:02d}:{m:02d}:{s:02d}',
        'locked': locked,
        'duration': 180,
        'has_meta': True,
    })

MOCK_EVENTS = []
for i in range(5):
    MOCK_EVENTS.append({
        'timestamp': f'2026-06-20T{14+i}:3{i}:00',
        'g_force': round(random.uniform(0.8, 1.5), 2),
        'type': random.choice(['impact', 'parking_motion', 'manual']),
        'segment': f'20260620_{14+i}3{i}00.mp4',
    })

MOCK_CONFIG = {
    'camera': {
        'width': '1920', 'height': '1080', 'framerate': '30',
        'codec': 'h264', 'bitrate': '10000000', 'profile': 'high',
        'segment_duration': '180',
    },
    'storage': {'max_usage': '85', 'target_usage': '80'},
    'imu': {'accel_threshold': '0.8', 'debounce_ms': '50'},
    'parking': {'entry_timeout': '300'},
    'gps': {'osd_overlay': 'false'},
    'wifi': {'ssid': 'hivehacker58CC', 'password': 'hivehak!', 'channel': '6'},
    'led': {
        'power_enabled': True,
        'gps_enabled': True,
        'rec_enabled': True,
    },
    'email': {
        'smtp_server': 'smtp.gmail.com',
        'smtp_port': '587',
        'smtp_user': '',
        'smtp_password': '',
        'from_email': '',
        'enabled': 'false',
    },
}

LED_JSON_PATH = '/tmp/led.json'
LED_CONFIG_PATH = '/mnt/data/config/led_config.json'
LED_NAMES = {0: 'power', 1: 'gps', 2: 'rec'}
LED_INDICES = {'power': 0, 'gps': 1, 'rec': 2}

# Simple session-based auth (for preview)
PASSWORD_SET = False
LOGGED_IN = True  # Auto-logged in for preview


@app.route('/')
def splash():
    """Captive portal splash page — auto-pops up when connecting to Wi-Fi."""
    return render_template('splash.html', ssid='hivehacker58CC', password_set=PASSWORD_SET)


@app.route('/dashboard')
def dashboard():
    """Main dashboard with live preview thumbnail + status."""
    return render_template('index.html')


@app.route('/recordings')
def recordings():
    """File browser — download, play, share, email recordings."""
    return render_template('recordings.html', files=MOCK_RECORDINGS)


@app.route('/stream')
def stream():
    """Live preview page (full screen)."""
    return render_template('stream.html')


@app.route('/settings')
def settings():
    """Settings page."""
    return render_template('settings.html', config=MOCK_CONFIG)


@app.route('/events')
def events():
    """Events log page."""
    return render_template('events.html', events=MOCK_EVENTS)


@app.route('/firmware')
def firmware():
    """Firmware update page."""
    return render_template('firmware.html')


# === AUTH API ===

@app.route('/api/auth/check')
def api_auth_check():
    return jsonify({
        'login_required': PASSWORD_SET,
        'ssid': 'hivehacker58CC',
    })


@app.route('/api/auth/login', methods=['POST'])
def api_auth_login():
    data = request.json
    # In real version, check against stored password
    return jsonify({'success': True})


# === STATUS API ===

@app.route('/api/status')
def api_status():
    """Mock system status for preview."""
    return jsonify({
        'mode': 'RECORDING',
        'recording': True,
        'recording_time': '00:15:32',
        'storage': {
            'total_gb': 32.0,
            'used_gb': 18.5,
            'free_gb': 13.5,
            'percentage': 57.8,
            'estimated_remaining_hours': 3.0,
        },
        'cpu_temp': 42.3,
        'uptime_seconds': 932,
        'recordings_count': 15,
        'locked_count': 3,
        'wifi_clients': 1,
        'gps': {'fix': True, 'sats': 8, 'speed': 0.0},
        'led_state': 'RECORDING',
        'led_config': _load_led_config(),
        'current_segment': '20260620_151500.mp4',
        'segment_elapsed': 32,
    })


# === RECORDINGS API ===

@app.route('/api/recordings')
def api_recordings():
    return jsonify({'files': MOCK_RECORDINGS, 'total': len(MOCK_RECORDINGS)})


@app.route('/api/recordings/<filename>/meta')
def api_recording_meta(filename):
    return jsonify({
        'filename': filename,
        'gps_track': [{'lat': 43.6532, 'lon': -79.3832, 'speed': 45.2}],
        'imu_summary': {'max_accel': 0.3},
    })


@app.route('/api/recordings/<filename>/email', methods=['POST'])
def api_email_recording(filename):
    """Email a recording via configured SMTP."""
    data = request.json or {}
    to_email = data.get('to', '')
    return jsonify({'status': 'sent', 'to': to_email, 'filename': filename})


# === SETTINGS API ===

@app.route('/api/settings', methods=['GET', 'POST'])
def api_settings():
    if request.method == 'GET':
        return jsonify(MOCK_CONFIG)
    elif request.method == 'POST':
        data = request.json
        MOCK_CONFIG.update(data)
        return jsonify({'status': 'saved'})

# === LED API ===

def _load_led_config():
    """Load persisted LED enable/disable config."""
    try:
        with open(LED_CONFIG_PATH, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {'power_enabled': True, 'gps_enabled': True, 'rec_enabled': True}

def _save_led_config(config):
    """Persist LED config to data partition."""
    os.makedirs(os.path.dirname(LED_CONFIG_PATH), exist_ok=True)
    with open(LED_CONFIG_PATH, 'w') as f:
        json.dump(config, f)

def _write_led_json(power_on, gps_on, rec_on):
    """Write LED state to /tmp/led.json for the led-controller binary."""
    leds = [
        {'index': 0, 'red': 0, 'blue': 255, 'green': 0, 'on': power_on},
        {'index': 1, 'red': 0, 'blue': 100, 'green': 255, 'on': gps_on},
        {'index': 2, 'red': 255, 'blue': 0, 'green': 0, 'on': rec_on},
    ]
    data = {'leds': leds}
    try:
        tmp = LED_JSON_PATH + '.tmp'
        with open(tmp, 'w') as f:
            json.dump(data, f)
        os.rename(tmp, LED_JSON_PATH)
    except Exception as e:
        print(f"LED JSON write error: {e}")

@app.route('/api/led/<name>', methods=['POST'])
def api_led_toggle(name):
    """Toggle an individual LED on/off. name = power|gps|rec."""
    if name not in LED_INDICES:
        return jsonify({'error': 'Unknown LED: ' + name}), 400

    data = request.json or {}
    enabled = bool(data.get('enabled', False))

    config = _load_led_config()
    config[name + '_enabled'] = enabled
    _save_led_config(config)

    # Build current LED state from config
    power_on = config.get('power_enabled', True)
    gps_on = config.get('gps_enabled', True)
    rec_on = config.get('rec_enabled', True)

    _write_led_json(power_on, gps_on, rec_on)

    return jsonify({'status': 'ok', 'led': name, 'enabled': enabled})

@app.route('/api/led', methods=['GET'])
def api_led_status():
    """Get current LED config."""
    config = _load_led_config()
    return jsonify(config)


# === EVENTS API ===

@app.route('/api/events')
def api_events():
    return jsonify(MOCK_EVENTS)


@app.route('/api/events/export')
def api_events_export():
    csv = 'timestamp,g_force,type,segment\n'
    for e in MOCK_EVENTS:
        csv += f"{e['timestamp']},{e['g_force']},{e['type']},{e['segment']}\n"
    return Response(csv, mimetype='text/csv',
                    headers={'Content-Disposition': 'attachment; filename=events.csv'})


# === FIRMWARE API ===

@app.route('/api/firmware/upload', methods=['POST'])
def api_firmware_upload():
    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400
    return jsonify({'status': 'received', 'filename': request.files['file'].filename})


# === SYSTEM API ===

@app.route('/api/system/reboot', methods=['POST'])
def api_reboot():
    return jsonify({'status': 'rebooting'})


@app.route('/api/system/shutdown', methods=['POST'])
def api_shutdown():
    return jsonify({'status': 'shutting down'})


@app.route('/api/system/factory-reset', methods=['POST'])
def api_factory_reset():
    return jsonify({'status': 'reset complete, rebooting'})


if __name__ == '__main__':
    print("HiveHacker Web UI Preview")
    print("Open http://localhost:5555 in your browser")
    print("Press Ctrl+C to stop")
    app.run(host='0.0.0.0', port=5555, debug=True)