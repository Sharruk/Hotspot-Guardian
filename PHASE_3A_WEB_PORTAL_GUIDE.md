# Phase 3A: Hotspot Guardian Web Portal Demonstration Guide

## 1. Overview & Purpose

**Hotspot Guardian Web Portal** allows mobile devices (Phone A, Phone B) connected to the local Wi-Fi Hotspot to interact directly with the Windows Laptop application through their standard mobile web browsers (e.g. Chrome, Safari).

### Key Features Demonstrated
- **Local Network Routing**: Communication over an isolated local hotspot subnet (e.g., `10.154.93.0/24` or `192.168.43.0/24`) with zero cloud or Internet dependencies.
- **Client-Server Architecture**: Windows Laptop functions as the local HTTPS Server (`port 53317`) and the mobile phone acts as a Web Client.
- **Encrypted Local Transport**: TLS/HTTPS communication with self-signed certificate.
- **Real-Time Messaging**: Text messages sent from the browser are processed, stored locally, and logged in real-time.
- **Streaming File Upload**: Binary streaming upload with client-side progress tracking, real throughput calculation ($\text{MB/s}$ or $\text{KB/s}$), and duration tracking.
- **Centralized Event Journal**: Live server activity monitoring across `NETWORK`, `MESSAGE`, and `TRANSFER` categories.

---

## 2. Network Topology & Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     MOBILE HOTSPOT                      │
│                  (Subnet: 10.154.93.0/24)               │
└───────────────┬─────────────────────────────────┬───────┘
                │                                 │
                ▼                                 ▼
       ┌─────────────────┐               ┌─────────────────┐
       │     PHONE A     │               │ WINDOWS LAPTOP  │
       │ (Mobile Browser)│               │Hotspot Guardian │
       │ 10.154.93.x     │               │ 10.154.93.130   │
       └────────┬────────┘               └────────┬────────┘
                │                                 │
                │     HTTPS POST /message         │
                ├────────────────────────────────►│ (Logged in Event Log)
                │                                 │ (Saved as .txt file)
                │                                 │
                │     HTTPS POST /upload          │
                ├────────────────────────────────►│ (Streamed to Downloads)
                │                                 │ (Real-time speed & bytes)
                │                                 │
                │     HTTPS GET /status           │
                ├────────────────────────────────►│ (Live RTT Ping in ms)
                │                                 │
```

---

## 3. Step-by-Step Demonstration Procedure

### Step 1: Start Hotspot & Connect Devices
1. On **Phone A**:
   - Turn **ON** Mobile Data (required by some phones to activate hotspot routing).
   - Turn **ON** Mobile Hotspot.
2. On **Windows Laptop**:
   - Connect Wi-Fi to Phone A's hotspot.
   - Note the assigned local IP (e.g., `10.154.93.130`).

### Step 2: Launch Windows Hotspot Guardian
Run the following command in PowerShell:
```powershell
$env:CL="/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS"
flutter run -d windows
```
- Observe the **Network Information** card showing:
  - **Interface**: `Wi-Fi`
  - **Local IPv4**: `10.154.93.130` (or your current Wi-Fi IP)
  - **Subnet / CIDR**: `10.154.93.0/24`
  - **Port**: `53317`
  - **WEB PORTAL**: `https://<YOUR-IP>:53317/`
- Observe the **Event Log** showing `Server listening on port 53317 (HTTPS/TLS ready)`.

---

### Step 3: Open the Web Portal on Phone
1. On **Phone A** (or any phone connected to the hotspot), open Chrome or Safari.
2. Navigate to the exact URL displayed on the laptop screen, for example:
   ```
   https://10.154.93.130:53317/
   ```
3. **Handle Local Certificate Prompt**:
   - When Chrome displays *"Your connection is not private"*, tap **Advanced** $\rightarrow$ **Proceed to 10.154.93.130 (unsafe)**.
4. The **Hotspot Guardian Web Portal** will load immediately.
5. In the Windows app, observe the Event Log:
   ```
   [NETWORK] Web client connected (10.154.93.x)
   ```

---

### Step 4: Latency / Ping Test
1. In the Web Portal on the phone, tap **⚡ Ping Server (Measure RTT)**.
2. The phone sends an HTTP probe to `/api/hotspot/status` and calculates the round-trip time in milliseconds (e.g. `12 ms`).
3. The Activity Journal logs the measured latency.

---

### Step 5: Real-Time Message Test
1. In the Web Portal under **Send Message to Laptop**:
   - Type: `Hello from Phone A over local hotspot!`
   - Tap **Send Message**.
2. **Phone Verification**:
   - Alert dialog shows: *"✅ Message delivered to Windows Hotspot Guardian!"*.
   - Activity Journal shows: `[MESSAGE] Sent: "Hello from Phone A over local hotspot!"`.
3. **Laptop Verification**:
   - Windows Hotspot Guardian Event Log displays:
     ```
     [MESSAGE] Browser message from 10.154.93.x: "Hello from Phone A over local hotspot!"
     [MESSAGE] Message saved to storage (Message 2026-09-02 20.55.00.txt)
     ```

---

### Step 6: File Upload & Throughput Test
1. In the Web Portal under **File Transfer to Laptop**:
   - Tap **Tap to Select File** and pick an image, PDF, or video (e.g., 5 MB – 50 MB).
   - Review selected file name and size.
   - Tap **🚀 Upload File**.
2. **Phone Verification**:
   - Real-time progress bar fills from $0\%$ to $100\%$.
   - Live metrics display:
     - **Transferred**: e.g., `4.5 MB / 4.5 MB`
     - **Duration**: e.g., `0.8 s`
     - **Speed**: e.g., `5.62 MB/s`
3. **Laptop Verification**:
   - Windows Event Log records:
     ```
     [TRANSFER] Browser upload started from 10.154.93.x: photo.jpg
     [TRANSFER] Browser upload completed: photo.jpg (4718592 bytes in 0.84s, 5.62 MB/s)
     ```
   - The file is saved in the safe downloads/received directory.

---

## 4. Technical Specifications & Endpoints

| Endpoint | Method | Purpose | Payload | Response |
| :--- | :--- | :--- | :--- | :--- |
| `/` | `GET` | Serves Web Portal HTML/CSS/JS | None | HTML Document |
| `/api/hotspot/status` | `GET` | Ping & Host status probe | None | JSON (`alias`, `ip`, `port`, `status`) |
| `/api/hotspot/message` | `POST` | Browser $\rightarrow$ Laptop Message | JSON `{ "message": "..." }` | JSON (`success`, `timestamp`) |
| `/api/hotspot/upload` | `POST` | Browser $\rightarrow$ Laptop File Upload | Binary Stream (`?filename=...`) | JSON (`success`, `bytes`, `durationMs`, `speed`) |
| `/api/localsend/v2/info`| `GET` | Peer Info (LocalSend Protocol) | None | JSON Protocol Spec |

---

## 5. Troubleshooting

- **Browser says "Site can't be reached"**:
  - Verify phone is connected to the hotspot Wi-Fi.
  - Double check the laptop IP with `ipconfig` or the dashboard card.
  - Ensure you specified `https://` and port `:53317`.
- **Certificate Warning**:
  - Expected behavior for local self-signed TLS certificates. Tap **Advanced** $\rightarrow$ **Proceed**.
- **Windows Firewall Prompt**:
  - If prompted, click **Allow access** for Private and Public networks.

---

## 6. Project Viva / Report Points
- **Layer 3 (Network Layer)**: IPv4 addressing, subnet masks (`/24`), DHCP assignment by mobile hotspot.
- **Layer 4 (Transport Layer)**: Reliable connection-oriented TCP transmission on port `53317`.
- **Layer 7 (Application Layer)**: HTTP/1.1 protocol, REST APIs, streaming data transfer, TLS 1.3 encryption.
- **Performance Evaluation**: Real throughput calculation ($\text{MB/s}$) and network latency measurement (RTT in $\text{ms}$).
