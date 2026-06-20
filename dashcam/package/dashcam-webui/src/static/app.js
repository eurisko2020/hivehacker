// Dashcam Web UI - Client-side JavaScript

async function apiPost(url) {
    try {
        const res = await fetch(url, { method: 'POST' });
        return await res.json();
    } catch (e) {
        console.error('API error:', e);
    }
}

async function apiDelete(url) {
    try {
        const res = await fetch(url, { method: 'DELETE' });
        return await res.json();
    } catch (e) {
        console.error('API error:', e);
    }
}

async function saveSettings(event) {
    event.preventDefault();
    const form = event.target;
    const config = {};

    // Collect form data into nested config object
    const formData = new FormData(form);
    for (const [key, value] of formData.entries()) {
        const [section, field] = key.split('.');
        if (!config[section]) config[section] = {};
        config[section][field] = value;
    }

    try {
        const res = await fetch('/api/settings', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(config)
        });
        const result = await res.json();
        if (result.status === 'saved') {
            alert('Settings saved! Some changes may require a recording restart.');
        } else {
            alert('Error saving settings: ' + JSON.stringify(result));
        }
    } catch (e) {
        alert('Error: ' + e.message);
    }
}

async function testEvent() {
    // Simulate a G-sensor event for testing
    alert('Test event: This will trigger when dashcamd is running. Feature requires dashcamd API endpoint.');
}

// Auto-refresh recordings page every 30 seconds
if (window.location.pathname === '/recordings') {
    setInterval(() => {
        // Only auto-refresh if user is not interacting
        if (!document.querySelector('.btn:hover')) {
            // Could implement AJAX refresh here
        }
    }, 30000);
}