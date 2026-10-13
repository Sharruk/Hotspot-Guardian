import os
from PIL import Image, ImageDraw, ImageFont

diagrams_dir = 'documentation/diagrams'
os.makedirs(diagrams_dir, exist_ok=True)

def create_box(draw, x, y, w, h, title, subtitle="", bg="#161b22", border="#30363d", text_color="#58a6ff", sub_color="#8b949e"):
    draw.rounded_rectangle([(x, y), (x + w, y + h)], radius=8, fill=bg, outline=border, width=2)
    draw.text((x + 12, y + 10), title, fill=text_color)
    if subtitle:
        draw.text((x + 12, y + 30), subtitle, fill=sub_color)

def draw_arrow(draw, x1, y1, x2, y2, color="#58a6ff", width=2, label=""):
    draw.line([(x1, y1), (x2, y2)], fill=color, width=width)
    # arrow head
    if x2 > x1: # pointing right
        draw.polygon([(x2, y2), (x2 - 8, y2 - 5), (x2 - 8, y2 + 5)], fill=color)
        if label:
            draw.text((x1 + 10, y1 - 18), label, fill="#c9d1d9")
    elif x2 < x1: # pointing left
        draw.polygon([(x2, y2), (x2 + 8, y2 - 5), (x2 + 8, y2 + 5)], fill=color)
        if label:
            draw.text((x2 + 10, y2 - 18), label, fill="#c9d1d9")
    elif y2 > y1: # pointing down
        draw.polygon([(x2, y2), (x2 - 5, y2 - 8), (x2 + 5, y2 - 8)], fill=color)
        if label:
            draw.text((x1 + 8, (y1 + y2)//2 - 8), label, fill="#c9d1d9")
    elif y2 < y1: # pointing up
        draw.polygon([(x2, y2), (x2 - 5, y2 + 8), (x2 + 5, y2 + 8)], fill=color)
        if label:
            draw.text((x1 + 8, (y1 + y2)//2 - 8), label, fill="#c9d1d9")

# ─────────────────────────────────────────────────────────────────────────────
# Diagram 1: Overall Hotspot Network Architecture
# ─────────────────────────────────────────────────────────────────────────────
d1 = Image.new('RGB', (1000, 520), color='#0d1117')
draw = ImageDraw.Draw(d1)
draw.text((20, 20), "Diagram 1: Hotspot Guardian Physical & Logical Network Architecture", fill="#ffffff")

create_box(draw, 50, 80, 260, 90, "Mobile Hotspot Gateway", "Phone SoftAP (10.66.85.199 / 4G Uplink)\nDHCP Server & Wi-Fi Access Point", bg="#1f242c", border="#f0883e", text_color="#f0883e")
create_box(draw, 370, 80, 260, 90, "Windows Guardian Host", "Laptop Node (IP: 10.66.85.129)\nFlutter App + Shelf Server (:53317)", bg="#161b22", border="#58a6ff", text_color="#58a6ff")
create_box(draw, 690, 80, 260, 90, "Mobile Browser Client", "Phone Browser (No App Required)\nAccesses https://10.66.85.129:53317/", bg="#161b22", border="#7ee787", text_color="#7ee787")

draw_arrow(draw, 310, 125, 370, 125, color="#f0883e", label="802.11 Wi-Fi")
draw_arrow(draw, 630, 125, 690, 125, color="#7ee787", label="HTTPS / TLS")

create_box(draw, 50, 240, 260, 230, "Layer 2/3 Discovery", "• Windows ARP Table (/arp -a)\n• Resolves MAC & Hostname\n• UDP Multicast 224.0.0.167\n• Subnet Sweep 10.66.85.0/24\n• Observed Neighbor Cache", bg="#161b22", border="#388bfd")
create_box(draw, 370, 240, 260, 230, "Core Application Services", "• Shelf HTTP/1.1 Engine\n• Self-Signed TLS X.509 Cert\n• Two-Way Live Chatroom Hub\n• Streamed IOSink File Pipe\n• Observed Traffic Accounting\n• Event Journal Singleton", bg="#161b22", border="#58a6ff")
create_box(draw, 690, 240, 260, 230, "Web Portal Capabilities", "• Zero-Install Browser Client\n• RTT Ping & Latency Probe\n• Two-Way Chat Messaging\n• Direct Stream File Upload\n• Instant Disk Persistence\n• Live Activity Journal", bg="#161b22", border="#7ee787")

draw_arrow(draw, 180, 170, 180, 240, color="#388bfd")
draw_arrow(draw, 500, 170, 500, 240, color="#58a6ff")
draw_arrow(draw, 820, 170, 820, 240, color="#7ee787")

d1.save(os.path.join(diagrams_dir, 'diag1_network_architecture.png'))

# ─────────────────────────────────────────────────────────────────────────────
# Diagram 2: Web Portal Request Flow
# ─────────────────────────────────────────────────────────────────────────────
d2 = Image.new('RGB', (1000, 480), color='#0d1117')
draw = ImageDraw.Draw(d2)
draw.text((20, 20), "Diagram 2: Web Portal Request Routing & Shelf Handlers", fill="#ffffff")

create_box(draw, 40, 80, 240, 60, "Web Browser Client", "Safari / Chrome on Android or iOS", bg="#161b22", border="#7ee787")
create_box(draw, 380, 80, 240, 60, "Shelf Pipeline (Receiver)", "Port 53317 (TLS SecurityContext)", bg="#161b22", border="#58a6ff")
create_box(draw, 720, 80, 240, 60, "Storage & State Layer", "AppState, Disk, TrafficSingleton", bg="#161b22", border="#a371f7")

draw_arrow(draw, 280, 110, 380, 110, color="#58a6ff", label="HTTPS Request")
draw_arrow(draw, 620, 110, 720, 110, color="#a371f7", label="Dispatch")

endpoints = [
    ("GET /", "Serves Web Portal SPA (HTML, CSS, JS)", "Browser UI Initialized"),
    ("GET /api/hotspot/status", "Returns host alias, server IP, and active port", "Status card rendered"),
    ("GET /api/hotspot/messages", "Polls live chat history every 2.5 seconds", "Chat feed updated"),
    ("POST /api/hotspot/message", "Ingests JSON text message from browser", "Logged to EventLog & Chat"),
    ("POST /api/hotspot/upload", "Streams binary file payload with zero buffering", "Saved to Downloads\\LanLink")
]

y = 170
for ep, desc, action in endpoints:
    create_box(draw, 40, y, 240, 45, ep, "", bg="#21262d", border="#388bfd", text_color="#58a6ff")
    create_box(draw, 320, y, 360, 45, desc, "", bg="#161b22", border="#30363d", text_color="#c9d1d9")
    create_box(draw, 720, y, 240, 45, action, "", bg="#161b22", border="#238636", text_color="#7ee787")
    y += 55

d2.save(os.path.join(diagrams_dir, 'diag2_web_portal_flow.png'))

# ─────────────────────────────────────────────────────────────────────────────
# Diagram 3: File Upload Sequence
# ─────────────────────────────────────────────────────────────────────────────
d3 = Image.new('RGB', (1000, 520), color='#0d1117')
draw = ImageDraw.Draw(d3)
draw.text((20, 20), "Diagram 3: Streaming File Upload Protocol Sequence", fill="#ffffff")

create_box(draw, 60, 70, 200, 45, "Client Browser", bg="#161b22", border="#7ee787")
create_box(draw, 400, 70, 200, 45, "Shelf Server (:53317)", bg="#161b22", border="#58a6ff")
create_box(draw, 740, 70, 200, 45, "Host Local Disk", bg="#161b22", border="#a371f7")

draw.line([(160, 115), (160, 480)], fill="#30363d", width=2)
draw.line([(500, 115), (500, 480)], fill="#30363d", width=2)
draw.line([(840, 115), (840, 480)], fill="#30363d", width=2)

steps = [
    (140, "1. User selects file & clicks Upload", 160, 500, "POST /api/hotspot/upload?filename=...", "#58a6ff", True),
    (200, "2. Server creates target path & opens IOSink", 500, 840, "uniqueOutputPath() -> openWrite()", "#a371f7", True),
    (260, "3. Streamed HTTP request chunks (No base64)", 160, 500, "req.read() Stream<List<int>>", "#7ee787", True),
    (320, "4. Pipe directly to disk with periodic flush", 500, 840, "sink.add(chunk) -> sink.flush()", "#a371f7", True),
    (380, "5. Close file sink & update ObservedTraffic", 500, 840, "sink.close() + recordWebUpload()", "#58a6ff", True),
    (440, "6. Return JSON 200 OK (speed, duration, bytes)", 500, 160, "200 OK {success: true, speed: ...}", "#7ee787", False)
]

for y_pos, title, x_start, x_end, label, col, is_right in steps:
    draw.text((x_start + 15 if is_right else x_end + 15, y_pos - 18), label, fill="#c9d1d9")
    draw_arrow(draw, x_start, y_pos, x_end, y_pos, color=col)

d3.save(os.path.join(diagrams_dir, 'diag3_file_upload_sequence.png'))

# ─────────────────────────────────────────────────────────────────────────────
# Diagram 4: Two-Way Messaging Sequence
# ─────────────────────────────────────────────────────────────────────────────
d4 = Image.new('RGB', (1000, 500), color='#0d1117')
draw = ImageDraw.Draw(d4)
draw.text((20, 20), "Diagram 4: Two-Way Web Portal Live Messaging Sequence", fill="#ffffff")

create_box(draw, 60, 70, 200, 45, "Client Phone Browser", bg="#161b22", border="#7ee787")
create_box(draw, 400, 70, 200, 45, "Hotspot Guardian Server", bg="#161b22", border="#58a6ff")
create_box(draw, 740, 70, 200, 45, "Laptop Host UI", bg="#161b22", border="#f0883e")

draw.line([(160, 115), (160, 460)], fill="#30363d", width=2)
draw.line([(500, 115), (500, 460)], fill="#30363d", width=2)
draw.line([(840, 115), (840, 460)], fill="#30363d", width=2)

msteps = [
    (140, "POST /api/hotspot/message {text: 'Hello'}", 160, 500, "#7ee787", True),
    (190, "Store in _portalMessages & EventLog", 500, 840, "#f0883e", True),
    (240, "Laptop UI shows Portal Chat notification", 500, 840, "#f0883e", True),
    (300, "Host clicks 'Portal Chat' & sends reply", 840, 500, "#58a6ff", False),
    (360, "broadcastPortalMessage({text: 'Reply'})", 500, 500, "#58a6ff", True),
    (410, "GET /api/hotspot/messages (2.5s poll) -> Renders live bubble", 500, 160, "#7ee787", False)
]

for y_pos, label, x_start, x_end, col, is_right in msteps:
    draw.text((x_start + 15 if is_right else x_end + 15, y_pos - 18), label, fill="#c9d1d9")
    draw_arrow(draw, x_start, y_pos, x_end, y_pos, color=col)

d4.save(os.path.join(diagrams_dir, 'diag4_messaging_sequence.png'))

# ─────────────────────────────────────────────────────────────────────────────
# Diagram 5: Device Discovery Workflow
# ─────────────────────────────────────────────────────────────────────────────
d5 = Image.new('RGB', (1000, 520), color='#0d1117')
draw = ImageDraw.Draw(d5)
draw.text((20, 20), "Diagram 5: Hybrid Device Discovery & Classification Engine", fill="#ffffff")

create_box(draw, 40, 80, 260, 75, "1. Network Initialization", "• Extract active IP & Subnet\n• Detect Default Gateway IP\n• Bind Multicast 224.0.0.167", bg="#161b22", border="#388bfd")
create_box(draw, 370, 80, 260, 75, "2. Windows ARP Cache Scan", "• Run 'arp -a' via ArpScanner\n• Extract IP & MAC mappings\n• Query Gateway BSSID / MAC", bg="#161b22", border="#58a6ff")
create_box(draw, 700, 80, 260, 75, "3. Subnet TCP Active Sweep", "• Scan 10.66.85.1-254 on :53317\n• Parallel Socket.connect probes\n• Measure RTT connection latency", bg="#161b22", border="#a371f7")

draw_arrow(draw, 300, 115, 370, 115, color="#58a6ff")
draw_arrow(draw, 630, 115, 700, 115, color="#a371f7")

draw_arrow(draw, 500, 155, 500, 210, color="#58a6ff")

create_box(draw, 250, 210, 500, 60, "Device Classification Decision Matrix", "Categorize device based on protocol response and web interactions", bg="#21262d", border="#f0883e")

draw_arrow(draw, 350, 270, 180, 340, color="#238636")
draw_arrow(draw, 500, 270, 500, 340, color="#388bfd")
draw_arrow(draw, 650, 270, 820, 340, color="#8b949e")

create_box(draw, 50, 340, 260, 140, "APP RECEIVER (Active)", "• Answered /api/localsend/v2/info\n• P2P encrypted file sharing active\n• Actions: [Send File], [Send Msg]", bg="#161b22", border="#238636", text_color="#7ee787")
create_box(draw, 370, 340, 260, 140, "WEB PORTAL (Active)", "• Client visited https://<ip>:53317/\n• Browser two-way chat active\n• Actions: [Portal Chat], [Link]", bg="#161b22", border="#388bfd", text_color="#58a6ff")
create_box(draw, 690, 340, 260, 140, "HOTSPOT CLIENT (ARP)", "• IP/MAC resolved via ARP table\n• Ready to connect via Web Portal\n• Actions: [Send Message (Portal)]", bg="#161b22", border="#8b949e", text_color="#c9d1d9")

d5.save(os.path.join(diagrams_dir, 'diag5_device_discovery_workflow.png'))

# ─────────────────────────────────────────────────────────────────────────────
# Diagram 6: Application Data Accounting Workflow
# ─────────────────────────────────────────────────────────────────────────────
d6 = Image.new('RGB', (1000, 480), color='#0d1117')
draw = ImageDraw.Draw(d6)
draw.text((20, 20), "Diagram 6: Observed Application Data Accounting Architecture", fill="#ffffff")

create_box(draw, 50, 80, 260, 90, "Inbound Traffic (Rx)", "• Web Portal file uploads\n• Web chat text messages\n• P2P file transfers received", bg="#161b22", border="#238636", text_color="#7ee787")
create_box(draw, 370, 80, 260, 90, "ObservedTraffic Singleton", "• totalBytesReceived & totalBytesSent\n• messageCount & uploadCount\n• lastSpeed, peakSpeed, duration", bg="#21262d", border="#58a6ff", text_color="#58a6ff")
create_box(draw, 690, 80, 260, 90, "Outbound Traffic (Tx)", "• Web Portal chat broadcasts\n• P2P files sent to peers\n• LocalSend manifest payloads", bg="#161b22", border="#f0883e", text_color="#f0883e")

draw_arrow(draw, 310, 125, 370, 125, color="#7ee787", label="recordWebUpload()")
draw_arrow(draw, 690, 125, 630, 125, color="#f0883e", label="recordOutgoing()")

create_box(draw, 100, 240, 800, 80, "Strict Scope Boundary & Cellular WAN Disclaimer", 
           "CRITICAL PRINCIPLE: Hotspot Guardian records ONLY traffic explicitly handled by its local sockets.\n"
           "Total WAN / cellular data consumed by other phones cannot be observed from a Wi-Fi client without router access.", 
           bg="#2d2218", border="#d29922", text_color="#f0883e")

create_box(draw, 100, 360, 380, 80, "Real-Time Speed Metrics", "Speed = Delta Bytes / Delta Time\nSmoothed peak tracking across session", bg="#161b22", border="#388bfd")
create_box(draw, 520, 360, 380, 80, "Per-Client Traffic Records", "ClientTrafficRecord(ip, rx, tx, lastSeen)\nLinked to device items in dashboard", bg="#161b22", border="#a371f7")

d6.save(os.path.join(diagrams_dir, 'diag6_traffic_accounting_workflow.png'))

# ─────────────────────────────────────────────────────────────────────────────
# Diagram 7: User Workflow
# ─────────────────────────────────────────────────────────────────────────────
d7 = Image.new('RGB', (1000, 480), color='#0d1117')
draw = ImageDraw.Draw(d7)
draw.text((20, 20), "Diagram 7: End-to-End User Experience & Interaction Workflow", fill="#ffffff")

steps7 = [
    ("1. Host Laptop", "Enable Mobile Hotspot &\nLaunch Hotspot Guardian"),
    ("2. Client Phone", "Connect to Hotspot Wi-Fi\n(No App Download Needed)"),
    ("3. Browser Open", "Open https://<ip>:53317/\nView Live Web Portal"),
    ("4. Live Chat", "Two-way text messaging\nbetween Laptop & Phone"),
    ("5. File Sharing", "Select and stream files\ndirectly into Downloads")
]

x = 40
for title, desc in steps7:
    create_box(draw, x, 120, 160, 110, title, desc, bg="#161b22", border="#58a6ff")
    if x < 760:
        draw_arrow(draw, x + 160, 175, x + 200, 175, color="#58a6ff")
    x += 190

create_box(draw, 40, 280, 920, 160, "Key Architectural Benefits for Faculty Evaluation", 
           "• Zero Infrastructure Dependency: Functions anywhere without an active Internet uplink or cloud relay.\n"
           "• Zero Friction for Peers: Web Portal eliminates the mandatory APK installation barrier for guest phones.\n"
           "• True Streaming Pipeline: Large multi-megabyte files transfer in constant O(1) memory via HTTP streaming.\n"
           "• Complete Network Visibility: ARP-based client discovery, latency measurement, and event audit trail.",
           bg="#161b22", border="#238636", text_color="#7ee787")

d7.save(os.path.join(diagrams_dir, 'diag7_user_workflow.png'))

print("All 7 diagrams generated successfully!")
