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
    'led': {'brightness': '255'},
    'email': {
        'smtp_server': 'smtp.gmail.com',
        'smtp_port': '587',
        'smtp_user': '',
        'smtp_password': '',
        'from_email': '',
        'enabled': 'false',
    },
}

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