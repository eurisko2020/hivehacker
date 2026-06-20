// HiveHacker Web UI — Client JavaScript

// Theme management
function toggleTheme() {
    const html = document.documentElement;
    const current = html.getAttribute('data-theme');
    const next = current === 'dark' ? 'light' : 'dark';
    html.setAttribute('data-theme', next);
    localStorage.setItem('hivehacker-theme', next);
    updateThemeButton(next);
}

function updateThemeButton(theme) {
    const btn = document.querySelector('.theme-toggle');
    if (btn) btn.textContent = theme === 'dark' ? '☀️' : '🌙';
}

// Load saved theme
(function() {
    const saved = localStorage.getItem('hivehacker-theme') || 'light';
    document.documentElement.setAttribute('data-theme', saved);
    setTimeout(() => updateThemeButton(saved), 100);
})();

// API helpers
async function apiPost(url, data) {
    try {
        const res = await fetch(url, { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(data||{}) });
        return await res.json();
    } catch(e) { console.error('API error:', e); }
}

async function apiDelete(url) {
    try {
        const res = await fetch(url, { method: 'DELETE' });
        return await res.json();
    } catch(e) { console.error('API error:', e); }
}

// Modal helpers
function closeModal(id) {
    document.getElementById(id).classList.remove('active');
}

// Close modal on overlay click
document.addEventListener('click', function(e) {
    if (e.target.classList.contains('modal-overlay')) {
        e.target.classList.remove('active');
    }
});

// Settings form
async function saveSettings(event) {
    event.preventDefault();
    const form = event.target;
    const config = {};
    const formData = new FormData(form);
    for (const [key, value] of formData.entries()) {
        const [section, field] = key.split('.');
        if (!config[section]) config[section] = {};
        config[section][field] = value;
    }
    try {
        const res = await fetch('/api/settings', {
            method: 'POST', headers: {'Content-Type':'application/json'},
            body: JSON.stringify(config)
        });
        const result = await res.json();
        if (result.status === 'saved') {
            alert('Settings saved! Some changes may require a recording restart.');
        } else {
            alert('Error: ' + JSON.stringify(result));
        }
    } catch(e) { alert('Error: ' + e.message); }
}