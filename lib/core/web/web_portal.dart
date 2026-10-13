/// Provides the self-contained HTML/CSS/JavaScript client for the
/// Hotspot Guardian Local Web Portal.
///
/// Served directly by the Shelf HTTPS server at `GET /` and `GET /index.html`.
class WebPortal {
  WebPortal._();

  static String buildHtml({
    required String hostAlias,
    required String serverIp,
    required int serverPort,
    required String protocolVersion,
  }) {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Hotspot Guardian — Web Portal</title>
  <style>
    :root {
      --bg: #0f1117;
      --card-bg: #181c27;
      --card-border: #262c3e;
      --accent: #3b82f6;
      --accent-hover: #2563eb;
      --accent-rgb: 59, 130, 246;
      --success: #10b981;
      --success-rgb: 16, 185, 129;
      --warning: #f59e0b;
      --danger: #ef4444;
      --text: #f3f4f6;
      --text-muted: #9ca3af;
      --font: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: var(--font);
      line-height: 1.5;
      padding: 16px;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    .container {
      width: 100%;
      max-width: 600px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    header {
      text-align: center;
      padding: 12px 0 8px;
    }
    .badge-icon {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 44px;
      height: 44px;
      border-radius: 50%;
      background: rgba(var(--accent-rgb), 0.15);
      border: 1px solid var(--accent);
      color: var(--accent);
      font-size: 22px;
      margin-bottom: 8px;
    }
    h1 {
      font-size: 20px;
      font-weight: 800;
      letter-spacing: 0.5px;
      color: #fff;
    }
    .subtitle {
      font-size: 12px;
      color: var(--text-muted);
      margin-top: 2px;
    }
    .card {
      background-color: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 14px;
      padding: 16px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25);
    }
    .card-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 12px;
      padding-bottom: 8px;
      border-bottom: 1px solid var(--card-border);
    }
    .card-title {
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 0.8px;
      text-transform: uppercase;
      color: var(--text-muted);
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .status-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 3px 10px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 600;
      background: rgba(var(--success-rgb), 0.15);
      color: var(--success);
      border: 1px solid var(--success);
    }
    .status-dot {
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: var(--success);
      box-shadow: 0 0 6px var(--success);
    }
    .grid-info {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
      font-size: 13px;
    }
    .info-item {
      background: rgba(0, 0, 0, 0.2);
      padding: 8px 12px;
      border-radius: 8px;
      border: 1px solid rgba(255, 255, 255, 0.04);
    }
    .info-label {
      font-size: 11px;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .info-value {
      font-weight: 600;
      color: #fff;
      font-family: monospace;
      margin-top: 2px;
    }
    textarea, input[type="text"] {
      width: 100%;
      background: #11141d;
      border: 1px solid var(--card-border);
      border-radius: 8px;
      padding: 10px 12px;
      color: #fff;
      font-family: inherit;
      font-size: 14px;
      resize: vertical;
      min-height: 70px;
      outline: none;
      transition: border-color 0.2s;
    }
    textarea:focus, input[type="text"]:focus {
      border-color: var(--accent);
    }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      width: 100%;
      background: var(--accent);
      color: #fff;
      border: none;
      border-radius: 8px;
      padding: 12px 16px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      transition: background 0.2s, transform 0.1s;
      margin-top: 10px;
    }
    .btn:hover {
      background: var(--accent-hover);
    }
    .btn:active {
      transform: scale(0.98);
    }
    .btn:disabled {
      opacity: 0.6;
      cursor: not-allowed;
      transform: none;
    }
    .btn-secondary {
      background: #252c3d;
      color: #e2e8f0;
      border: 1px solid var(--card-border);
    }
    .btn-secondary:hover {
      background: #2f374c;
    }
    .file-dropzone {
      border: 2px dashed var(--card-border);
      border-radius: 10px;
      padding: 20px 12px;
      text-align: center;
      cursor: pointer;
      background: rgba(0, 0, 0, 0.15);
      transition: border-color 0.2s, background 0.2s;
    }
    .file-dropzone:hover, .file-dropzone.dragover {
      border-color: var(--accent);
      background: rgba(var(--accent-rgb), 0.05);
    }
    .file-dropzone-icon {
      font-size: 28px;
      margin-bottom: 6px;
      color: var(--accent);
    }
    .file-meta {
      margin-top: 10px;
      padding: 8px 12px;
      background: #11141d;
      border-radius: 8px;
      font-size: 12px;
      display: none;
      align-items: center;
      justify-content: space-between;
      word-break: break-all;
    }
    .progress-wrap {
      margin-top: 12px;
      display: none;
    }
    .progress-bar {
      height: 8px;
      width: 100%;
      background: #11141d;
      border-radius: 4px;
      overflow: hidden;
    }
    .progress-fill {
      height: 100%;
      width: 0%;
      background: linear-gradient(90deg, var(--accent), var(--success));
      transition: width 0.15s ease-out;
    }
    .metrics-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 8px;
      margin-top: 10px;
      font-size: 11px;
      text-align: center;
    }
    .metric-box {
      background: rgba(0, 0, 0, 0.25);
      padding: 6px 4px;
      border-radius: 6px;
      border: 1px solid rgba(255, 255, 255, 0.04);
    }
    .metric-label {
      color: var(--text-muted);
      text-transform: uppercase;
      font-size: 9px;
    }
    .metric-value {
      font-weight: 700;
      color: #fff;
      font-family: monospace;
      margin-top: 2px;
      font-size: 12px;
    }
    .log-box {
      background: #10131c;
      border: 1px solid var(--card-border);
      border-radius: 8px;
      padding: 8px 10px;
      max-height: 140px;
      overflow-y: auto;
      font-family: monospace;
      font-size: 11px;
      color: #a0aec0;
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    .log-entry {
      line-height: 1.4;
      word-break: break-word;
    }
    .log-time {
      color: var(--text-muted);
    }
    .log-tag {
      font-weight: 700;
      color: var(--accent);
    }
    .log-tag.success { color: var(--success); }
    .log-tag.error { color: var(--danger); }
    .hidden-input {
      display: none;
    }
    footer {
      text-align: center;
      font-size: 11px;
      color: var(--text-muted);
      margin: 16px 0 8px;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div class="badge-icon">🛡️</div>
      <h1>HOTSPOT GUARDIAN</h1>
      <p class="subtitle">Local Hotspot Network Communication Portal</p>
    </header>

    <!-- 1. NETWORK STATUS CARD -->
    <div class="card">
      <div class="card-header">
        <span class="card-title">🌐 Network Status</span>
        <span class="status-pill" id="connStatus">
          <span class="status-dot"></span>
          <span>Connected</span>
        </span>
      </div>
      <div class="grid-info">
        <div class="info-item">
          <div class="info-label">Laptop IP</div>
          <div class="info-value" id="laptopIp">$serverIp</div>
        </div>
        <div class="info-item">
          <div class="info-label">Server Port</div>
          <div class="info-value">$serverPort (HTTPS)</div>
        </div>
        <div class="info-item">
          <div class="info-label">Host Name</div>
          <div class="info-value">$hostAlias</div>
        </div>
        <div class="info-item">
          <div class="info-label">Latency (RTT)</div>
          <div class="info-value" id="rttDisplay">-- ms</div>
        </div>
      </div>
      <button class="btn btn-secondary" style="margin-top: 10px; padding: 8px 12px; font-size: 12px;" onclick="testPing()">
        ⚡ Ping Server (Measure RTT)
      </button>
    </div>

    <!-- 2. LIVE CHAT & MESSAGING CARD -->
    <div class="card">
      <div class="card-header">
        <span class="card-title">💬 Live Hotspot Chat & Messaging</span>
        <span style="font-size: 11px; color: var(--success); display: flex; align-items: center; gap: 4px;">
          <span style="width: 7px; height: 7px; border-radius: 50%; background: var(--success); display: inline-block;"></span>
          Two-way live
        </span>
      </div>
      <div class="chat-feed" id="chatFeed" style="max-height: 220px; min-height: 100px; overflow-y: auto; background: rgba(0,0,0,0.3); border: 1px solid var(--card-border); border-radius: 8px; padding: 10px; display: flex; flex-direction: column; gap: 8px; margin-bottom: 12px;">
        <div style="font-size: 12px; color: var(--text-muted); text-align: center; font-style: italic;" id="chatEmpty">
          No messages yet. Send a message to start chatting with the host laptop!
        </div>
      </div>
      <div style="display: flex; gap: 8px;">
        <input type="text" id="msgInput" placeholder="Type a message to host laptop..." style="flex: 1; padding: 10px 12px; background: rgba(0,0,0,0.3); border: 1px solid var(--card-border); border-radius: 8px; color: #fff; font-size: 13px;" onkeydown="if(event.key==='Enter') sendMessage()">
        <button class="btn" id="sendMsgBtn" style="padding: 10px 16px; width: auto; margin-top: 0;" onclick="sendMessage()">
          Send
        </button>
      </div>
    </div>

    <!-- 3. FILE TRANSFER CARD -->
    <div class="card">
      <div class="card-header">
        <span class="card-title">📁 File Transfer to Laptop</span>
      </div>
      <div class="file-dropzone" id="dropzone" onclick="document.getElementById('fileInput').click()">
        <div class="file-dropzone-icon">📥</div>
        <div style="font-weight: 600; font-size: 13px;">Tap to Select File</div>
        <div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">Photos, documents, videos, etc.</div>
      </div>
      <input type="file" id="fileInput" class="hidden-input" onchange="handleFileSelected(event)">

      <div class="file-meta" id="fileMeta">
        <div>
          <div style="font-weight: 600; color: #fff;" id="metaName">--</div>
          <div style="font-size: 10px; color: var(--text-muted);" id="metaSize">--</div>
        </div>
        <button class="btn-secondary" style="padding: 4px 8px; font-size: 11px; border-radius: 4px; cursor: pointer;" onclick="clearSelectedFile()">✕</button>
      </div>

      <div class="progress-wrap" id="progressWrap">
        <div style="display: flex; justify-content: space-between; font-size: 11px; margin-bottom: 4px;">
          <span id="transferStatusText" style="font-weight: 600; color: var(--text-muted);">Uploading...</span>
          <span id="progressPercent" style="font-weight: 700; color: #fff;">0%</span>
        </div>
        <div class="progress-bar">
          <div class="progress-fill" id="progressFill"></div>
        </div>
        <div class="metrics-grid">
          <div class="metric-box">
            <div class="metric-label">Transferred</div>
            <div class="metric-value" id="metricBytes">0 KB</div>
          </div>
          <div class="metric-box">
            <div class="metric-label">Duration</div>
            <div class="metric-value" id="metricDuration">0.0 s</div>
          </div>
          <div class="metric-box">
            <div class="metric-label">Speed</div>
            <div class="metric-value" id="metricSpeed">0 KB/s</div>
          </div>
        </div>
      </div>

      <button class="btn" id="uploadBtn" style="display: none;" onclick="uploadFile()">
        <span>🚀</span> Upload File
      </button>
    </div>

    <!-- 4. ACTIVITY & EVENT LOG -->
    <div class="card">
      <div class="card-header">
        <span class="card-title">📋 Activity Journal</span>
        <button class="btn-secondary" style="padding: 2px 8px; font-size: 10px; border-radius: 4px; cursor: pointer;" onclick="clearLogs()">Clear</button>
      </div>
      <div class="log-box" id="logBox">
        <div class="log-entry">
          <span class="log-time">[Init]</span> <span class="log-tag">PORTAL</span> Connected to Hotspot Guardian ($serverIp:$serverPort)
        </div>
      </div>
    </div>

    <footer>
      Hotspot Guardian • Computer Networks Mini-Project
    </footer>
  </div>

  <script>
    let selectedFile = null;
    let uploadXhr = null;

    function formatTime() {
      const d = new Date();
      const pad = (n) => String(n).padStart(2, '0');
      return `[\${pad(d.getHours())}:\${pad(d.getMinutes())}:\${pad(d.getSeconds())}]`;
    }

    function addLog(tag, message, type = 'info') {
      const box = document.getElementById('logBox');
      const entry = document.createElement('div');
      entry.className = 'log-entry';
      let tagClass = 'log-tag';
      if (type === 'success') tagClass += ' success';
      if (type === 'error') tagClass += ' error';
      entry.innerHTML = `<span class="log-time">\${formatTime()}</span> <span class="\${tagClass}">[\${tag}]</span> \${message}`;
      box.appendChild(entry);
      box.scrollTop = box.scrollHeight;
    }

    function clearLogs() {
      document.getElementById('logBox').innerHTML = '';
      addLog('PORTAL', 'Log cleared');
    }

    function formatBytes(bytes) {
      if (bytes === 0) return '0 B';
      const k = 1024;
      const sizes = ['B', 'KB', 'MB', 'GB'];
      const i = Math.floor(Math.log(bytes) / Math.log(k));
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    async function testPing() {
      const display = document.getElementById('rttDisplay');
      display.innerText = 'measuring...';
      const start = performance.now();
      try {
        const res = await fetch('/api/hotspot/status', { cache: 'no-store' });
        const elapsed = Math.round(performance.now() - start);
        if (res.ok) {
          display.innerText = `\${elapsed} ms`;
          addLog('NETWORK', `Ping round-trip: \${elapsed} ms`, 'success');
        } else {
          display.innerText = 'Err';
          addLog('NETWORK', `Ping failed: HTTP \${res.status}`, 'error');
        }
      } catch (err) {
        display.innerText = 'Timeout';
        addLog('NETWORK', `Ping error: \${err.message}`, 'error');
      }
    }

    let lastMsgCount = -1;
    async function fetchMessages() {
      try {
        const res = await fetch('/api/hotspot/messages', { cache: 'no-store' });
        if (!res.ok) return;
        const data = await res.json();
        if (!data.messages) return;
        const feed = document.getElementById('chatFeed');
        if (data.messages.length === 0) {
          feed.innerHTML = '<div style="font-size: 12px; color: var(--text-muted); text-align: center; font-style: italic;">No messages yet. Send a message to start chatting with the host laptop!</div>';
          return;
        }
        if (data.messages.length !== lastMsgCount) {
          lastMsgCount = data.messages.length;
          feed.innerHTML = '';
          data.messages.forEach(m => {
            const isHost = m.isFromHost;
            const item = document.createElement('div');
            item.style.cssText = isHost
              ? 'align-self: flex-start; background: #1e293b; border: 1px solid #334155; padding: 7px 11px; border-radius: 10px 10px 10px 2px; max-width: 85%; font-size: 13px;'
              : 'align-self: flex-end; background: #2563eb; color: #fff; padding: 7px 11px; border-radius: 10px 10px 2px 10px; max-width: 85%; font-size: 13px;';
            const senderTag = isHost
              ? `<span style="font-weight: 700; color: #60a5fa; font-size: 11px; display: block; margin-bottom: 2px;">💻 Host (\${m.senderAlias || 'Laptop'}) • \${m.time || ''}</span>`
              : `<span style="font-weight: 700; color: #93c5fd; font-size: 11px; display: block; margin-bottom: 2px;">📱 \${m.sender === 'Web Client' ? 'You' : m.sender} • \${m.time || ''}</span>`;
            item.innerHTML = `\${senderTag}<div>\${m.text}</div>`;
            feed.appendChild(item);
          });
          feed.scrollTop = feed.scrollHeight;
        }
      } catch (_) {}
    }

    async function sendMessage() {
      const input = document.getElementById('msgInput');
      const text = input.value.trim();
      if (!text) {
        alert('Please enter a message.');
        return;
      }
      const btn = document.getElementById('sendMsgBtn');
      btn.disabled = true;
      btn.innerText = 'Sending...';

      try {
        const res = await fetch('/api/hotspot/message', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ message: text })
        });
        const data = await res.json();
        if (res.ok && data.success) {
          addLog('MESSAGE', `Sent: "\${text}"`, 'success');
          input.value = '';
          await fetchMessages();
        } else {
          addLog('MESSAGE', `Failed to deliver message: \${data.error || 'Server error'}`, 'error');
          alert('❌ Delivery failed: ' + (data.error || 'Unknown error'));
        }
      } catch (err) {
        addLog('MESSAGE', `Network error: \${err.message}`, 'error');
        alert('❌ Error: ' + err.message);
      } finally {
        btn.disabled = false;
        btn.innerText = 'Send';
      }
    }

    function handleFileSelected(e) {
      const file = e.target.files && e.target.files[0];
      if (!file) return;
      selectedFile = file;
      document.getElementById('metaName').innerText = file.name;
      document.getElementById('metaSize').innerText = formatBytes(file.size);
      document.getElementById('fileMeta').style.display = 'flex';
      document.getElementById('uploadBtn').style.display = 'inline-flex';
      document.getElementById('progressWrap').style.display = 'none';
      addLog('FILE', `Selected file: \${file.name} (\${formatBytes(file.size)})`);
    }

    function clearSelectedFile() {
      selectedFile = null;
      document.getElementById('fileInput').value = '';
      document.getElementById('fileMeta').style.display = 'none';
      document.getElementById('uploadBtn').style.display = 'none';
      document.getElementById('progressWrap').style.display = 'none';
    }

    function uploadFile() {
      if (!selectedFile) {
        alert('Please select a file first.');
        return;
      }
      const file = selectedFile;
      const progressWrap = document.getElementById('progressWrap');
      const progressFill = document.getElementById('progressFill');
      const progressPercent = document.getElementById('progressPercent');
      const statusText = document.getElementById('transferStatusText');
      const metricBytes = document.getElementById('metricBytes');
      const metricDuration = document.getElementById('metricDuration');
      const metricSpeed = document.getElementById('metricSpeed');
      const uploadBtn = document.getElementById('uploadBtn');

      progressWrap.style.display = 'block';
      uploadBtn.disabled = true;
      progressFill.style.width = '0%';
      progressPercent.innerText = '0%';
      statusText.innerText = 'Uploading...';
      statusText.style.color = 'var(--text-muted)';

      const startTime = performance.now();
      addLog('TRANSFER', `Started upload: \${file.name} (\${formatBytes(file.size)})`);

      const xhr = new XMLHttpRequest();
      uploadXhr = xhr;

      xhr.upload.onprogress = (event) => {
        if (event.lengthComputable) {
          const loaded = event.loaded;
          const total = event.total;
          const pct = Math.round((loaded / total) * 100);
          progressFill.style.width = pct + '%';
          progressPercent.innerText = pct + '%';

          const elapsedSec = (performance.now() - startTime) / 1000;
          metricBytes.innerText = `\${formatBytes(loaded)} / \${formatBytes(total)}`;
          metricDuration.innerText = elapsedSec.toFixed(1) + ' s';

          if (elapsedSec > 0.05) {
            const speedBytesPerSec = loaded / elapsedSec;
            metricSpeed.innerText = formatBytes(speedBytesPerSec) + '/s';
          }
        }
      };

      xhr.onload = () => {
        uploadBtn.disabled = false;
        const totalDuration = ((performance.now() - startTime) / 1000).toFixed(2);
        if (xhr.status >= 200 && xhr.status < 300) {
          progressFill.style.width = '100%';
          progressPercent.innerText = '100%';
          statusText.innerText = 'Completed ✅';
          statusText.style.color = 'var(--success)';
          const avgSpeed = formatBytes(file.size / Math.max(0.001, (performance.now() - startTime) / 1000)) + '/s';
          metricDuration.innerText = totalDuration + ' s';
          metricSpeed.innerText = avgSpeed;
          addLog('TRANSFER', `Upload finished: \${file.name} in \${totalDuration}s (\${avgSpeed})`, 'success');
          alert(`✅ File "\${file.name}" uploaded successfully!\\nDuration: \${totalDuration}s\\nAvg Speed: \${avgSpeed}`);
        } else {
          statusText.innerText = 'Failed ❌';
          statusText.style.color = 'var(--danger)';
          addLog('TRANSFER', `Upload failed: HTTP \${xhr.status}`, 'error');
          alert('❌ Upload failed: HTTP ' + xhr.status);
        }
      };

      xhr.onerror = () => {
        uploadBtn.disabled = false;
        statusText.innerText = 'Network Error ❌';
        statusText.style.color = 'var(--danger)';
        addLog('TRANSFER', `Upload error: network failure`, 'error');
        alert('❌ Network transfer error. Please check hotspot connection.');
      };

      const url = '/api/hotspot/upload?filename=' + encodeURIComponent(file.name);
      xhr.open('POST', url, true);
      xhr.setRequestHeader('Content-Type', file.type || 'application/octet-stream');
      xhr.send(file);
    }

    // Auto-ping and load chat on load
    window.addEventListener('DOMContentLoaded', () => {
      setTimeout(testPing, 600);
      fetchMessages();
      setInterval(fetchMessages, 2500);
    });
  </script>
</body>
</html>
''';
  }
}
