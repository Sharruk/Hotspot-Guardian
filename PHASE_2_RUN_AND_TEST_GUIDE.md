# Hotspot Guardian: Phase 2 Run & Real-World Test Guide

> **Project Title:** Hotspot Guardian: Local Hotspot Network Monitoring and Communication System  
> **Course:** Semester 5 Computer Networks Mini-Project  
> **Target Status:** Phase 2 Real-World Verification Guide (Phase 3 is NOT started)  

---

## 1. Project Overview

**Hotspot Guardian** is a lightweight Computer Networks demonstration system designed to run on a local Wi-Fi / Mobile Hotspot network. 

The system demonstrates core networking concepts in real time:
- Local IPv4 network interface inspection and `/24` subnet derivation
- Peer discovery across mobile hotspots (UDP Multicast on `224.0.0.167:53317` + unicast TCP subnet probing on port `53317`)
- Real TCP Round-Trip Time (RTT) latency measurement in milliseconds ($ms$)
- Laptop-to-Phone text messaging and bidirectional file transfer over TLS/HTTPS
- Structured real-time Network Event Logging (`[SERVER]`, `[NETWORK]`, `[DISCOVERY]`, `[PING]`, `[MESSAGE]`, `[TRANSFER]`)

---

## 2. Current Implementation Verification

### Windows Application (Laptop)
- [x] **Hotspot Guardian Dashboard:** Replaced mobile UI with a 4-card CN dashboard (`lib/ui/shell/home_page.dart`).
- [x] **Network Information Card:** Displays Interface Name, Local IPv4, `/24` Subnet CIDR, Server Port, and `Connected & Active` status.
- [x] **Detected Devices Table:** Lists discovered nodes with Alias, IP:Port, Model, `ONLINE` / `UNREACHABLE` badge, Latency ($ms$), **Msg** button, and **Send File** button.
- [x] **Active Network Transfers Section:** Live progress bar, speed ($MB/s$), and ETA.
- [x] **Network Event Log:** Live scrollable terminal journal with category badges and copy-to-clipboard functionality.
- [x] **Real Latency Timing:** Uses raw TCP socket handshake timing (`AppState.measurePeerLatency`). No fake or randomized latency.

### Android Application (Phone B)
- [x] **Shelf HTTPS Receiver:** Automatically starts on port `53317` at app launch.
- [x] **Discovery Responder:** Answers `/api/localsend/v2/info` on port `53317` when scanned.
- [x] **Message Presentation:** Distinguishes text messages from generic files and renders clean `"Text Message"` dialogs with 1-tap **Copy message**.
- [x] **File Saving:** Writes received files into user-accessible storage and indexes them with Android MediaStore.

---

## 3. Physical Hardware Requirements & Three-Device Topology

The physical demonstration requires **three devices**:

```
                            PHONE A
                  (Mobile Data ON + Hotspot ON)
                               📱
                               │
                         Wi-Fi Hotspot
                         (192.168.43.1)
                               │
                 ┌─────────────┴─────────────┐
                 │                           │
          WINDOWS LAPTOP                  PHONE B
       (Hotspot Guardian App)      (Hotspot Guardian App)
                 💻                          📱
           192.168.43.x                192.168.43.y
                 │                           │
                 └──────── Local LAN ────────┘
                  • Peer Discovery
                  • TCP Latency Ping (ms)
                  • Text Messaging
                  • File Transfer
```

1. **Phone A (Hotspot Gateway):**
   - Provides the local Wi-Fi network (typically subnet `192.168.43.0/24`).
   - Does **not** run the app. It only acts as the router/access point.
2. **Windows Laptop (Guardian Monitor):**
   - Connects to Phone A's hotspot via Wi-Fi.
   - Runs Hotspot Guardian Windows dashboard.
3. **Phone B (Guardian Client Node):**
   - Connects to Phone A's hotspot via Wi-Fi.
   - Runs Hotspot Guardian Android app.

---

## 4. Windows Laptop Setup & Run Instructions

### Step 1: Open PowerShell in Project Directory
Navigate to the project root:
```powershell
cd d:\Visual_Studio_Code\College_Assignments\sem_5\Computer_Networks\Mini_Project\lanlink
```

### Step 2: Set MSVC Coroutine Workaround
```powershell
$env:CL="/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS"
```

### Step 3: Clean & Fetch Dependencies
```powershell
flutter clean
flutter pub get
```

### Step 4: Run Windows Application
```powershell
flutter run -d windows
```

> **Firewall Note:** When launching for the first time, Windows Defender Firewall will ask to allow network access. Check both **Private** and **Public** networks and click **Allow access**.

---

## 5. Android APK Build & Setup

### Environment Pre-check
Run:
```powershell
flutter doctor -v
```

If `flutter doctor` reports `[X] Android toolchain - Unable to locate Android SDK`, link your installed Android SDK path:
```powershell
flutter config --android-sdk "C:\Users\Welcome\AppData\Local\Android\Sdk"
```
*(Replace with your actual Android SDK directory if installed elsewhere).*

### Build Debug APK
Once the SDK is linked, run:
```powershell
flutter build apk --debug
```

### Generated APK Output Location
The compiled APK will be created at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

---

## 6. APK Installation on Phone B

1. **Transfer the APK to Phone B:**
   - Connect Phone B to your laptop via USB cable and copy `app-debug.apk` to Phone B's `Download` folder, **OR**
   - Send `app-debug.apk` to Phone B via WhatsApp / Telegram / Google Drive / Email.
2. **Install the APK:**
   - Open the **Files** / **File Manager** app on Phone B.
   - Tap `app-debug.apk`.
   - If prompted with *"For your security, your phone is not allowed to install unknown apps from this source"*, tap **Settings** and toggle **Allow from this source**.
   - Tap **Install**.
3. **Launch the App:**
   - Open **Hotspot Guardian** (or **LanLink**) on Phone B.
   - On first run, confirm your device alias (e.g. `Pixel-PhoneB` or `Samsung-PhoneB`).
   - Grant storage and notification permissions when prompted.

---

## 7. Step-by-Step Physical Demonstration Procedure

Follow these steps in exact chronological order:

### [Step 1] Setup Hotspot (Phone A)
- On **Phone A**, turn **Mobile Data ON**.
- Turn **Personal Hotspot (Portable Hotspot) ON**.
- Note the SSID name and password.

### [Step 2] Connect Laptop to Hotspot
- On the Windows Laptop, connect Wi-Fi to Phone A's hotspot.
- Verify Wi-Fi is connected.

### [Step 3] Connect Phone B to Hotspot
- On Phone B, connect Wi-Fi to the same Phone A hotspot.
- Verify Phone B is connected.

### [Step 4] Start Android App (Phone B)
- Launch Hotspot Guardian on Phone B.
- Leave Phone B on the main screen (Receiver is active on port `53317`).

### [Step 5] Start Windows App (Laptop)
- Launch Hotspot Guardian on Windows (`flutter run -d windows`).

### [Step 6] Inspect Network Information Card
- Check the top card on the Windows dashboard:
  - **Interface:** Shows Wi-Fi adapter.
  - **Local IPv4:** Shows laptop's assigned IP (e.g., `192.168.43.102`).
  - **Subnet / CIDR:** Shows `192.168.43.0/24`.
  - **Port:** Shows `53317`.
  - **Status:** Shows `Connected & Active` (Green).

### [Step 7] Verify Device Discovery
- Look at the **Detected Devices on Hotspot** card:
  - Phone B will appear with its alias, IP address (e.g., `192.168.43.55:53317`), and `ONLINE` status.

### [Step 8] Verify Latency Measurement
- Observe the latency badge on Phone B's row (e.g., `8 ms` or `14 ms`).
- Tap the **refresh / ping** icon next to the latency badge to execute a fresh TCP handshake timing test.

### [Step 9] Send Test Text Message (Laptop → Phone B)
- On Windows, click the **Msg** button next to Phone B.
- Type: `Hello from Hotspot Guardian Windows!`
- Click **Send Message**.
- On Phone B:
  - An incoming request appears; tap **Accept**.
  - A card displays `"Text Message"`.
  - Tap the card to view the full message text and copy it.

### [Step 10] Send Test File (Laptop → Phone B)
- On Windows, click **Send File** next to Phone B.
- Pick a small image or PDF file.
- On Phone B, tap **Accept**.
- Watch real-time speed and progress bar on both screens.
- When finished, verify the file is stored in Phone B's `Download` folder.

### [Step 11] Verify Event Log
- Inspect the **Network Event Log** at the bottom of the Windows dashboard.
- Verify live timestamped entries:
  - `[SERVER] Server listening on port 53317`
  - `[NETWORK] Active interface: Wi-Fi | IP: 192.168.43.x | Subnet: 192.168.43.0/24`
  - `[DISCOVERY] Device detected: Phone B (192.168.43.y:53317)`
  - `[PING] Ping to Phone B -> Xms`
  - `[MESSAGE] Sending message to Phone B...`
  - `[TRANSFER] File transfer to Phone B completed successfully`

---

## 8. Expected Test Results Matrix

| Test Case | Action | Expected Result | What It Demonstrates |
|---|---|---|---|
| **1. Network Adapter** | Launch Windows App | Local IP and `/24` subnet rendered | Dynamic socket/interface querying without hardcoding |
| **2. Node Discovery** | Phone B joins hotspot & opens app | Phone B appears in table within 2–6s | UDP multicast & `/24` TCP port `53317` scanning |
| **3. Latency Check** | Observe latency badge | Displays real round-trip time in $ms$ | Live TCP socket connection handshake measurement |
| **4. Text Message** | Click **Msg** & send text | Text arrives on Phone B instantly | HTTP/TLS payload staging & peer-to-peer data delivery |
| **5. File Transfer** | Click **Send File** | File transfers with live speed ($MB/s$) | Binary stream transfer over HTTPS with progress tracking |
| **6. Diagnostics Log** | Inspect bottom card | Monospace event log with category chips | Live system and network audit journal |

---

## 9. Troubleshooting Common Issues

### Issue 1: Phone B Does Not Appear in Detected Devices
- **Check 1 (Same Hotspot):** Verify both Laptop and Phone B are connected to Phone A's Wi-Fi. (Disable mobile data on Phone B to ensure it communicates exclusively over Wi-Fi).
- **Check 2 (App Running):** Verify Hotspot Guardian is in the foreground on Phone B.
- **Check 3 (Windows Firewall):** Ensure Windows Defender Firewall has allowed `flutter` / `lanlink.exe` on Private and Public networks.
- **Check 4 (Manual Rescan):** Click the **Rescan** (circular arrow) button on the top right of the Network Information card on Windows.

### Issue 2: Phone B Appears but Status is `UNREACHABLE`
- **Check 1 (IP Changed):** Phone B's DHCP lease may have changed; click the refresh ping icon on the device row to re-probe.
- **Check 2 (AP Isolation):** Verify Phone A's hotspot settings do not have "AP Isolation" or "Client Isolation" enabled.

### Issue 3: Text Message or File Transfer Fails with Timeout
- **Check 1 (Consent Sheet):** Check if Phone B is displaying the consent prompt sheet waiting for user approval.
- **Check 2 (Storage Permission):** On Phone B, ensure storage / media permission was granted.

---

## 10. Phase Verification Status

- **Source Code Verification:** **PASSED** (0 static analysis or compile errors).
- **Windows Build Verification:** **READY** (`flutter run -d windows` with MSVC warning flag).
- **Android APK Build:** **READY ONCE SDK IS LINKED** (`flutter config --android-sdk` + `flutter build apk --debug`).
- **Physical 3-Device Hotspot Test:** **PENDING USER PHYSICAL EXECUTION**.

---

> **IMPORTANT REMINDER:**  
> **Phase 3 (Metrics, Transfer Speed & Latency Visualization, and Academic Presentation) is NOT started.**  
> Please perform the physical test using this guide and report your findings before Phase 3 begins.
