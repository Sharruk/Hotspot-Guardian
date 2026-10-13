# Hotspot Guardian — Phase 4B Implementation Report
**Minimal UI and Network Monitoring Improvements**

---

## 1. Overview
This report documents the minimal UI, network monitoring, and host-to-device communication improvements completed for **Hotspot Guardian** (Computer Networks mini-project) on the `update` branch. 

All existing working behavior—including the Web Portal (HTTPS port 53317), file uploads, file downloads, RTT ping measurement, transfer statistics, received-file storage, and the Activity Journal—has been strictly preserved.

---

## 2. Files Changed

| File | Nature of Changes |
|---|---|
| `lib/ui/shell/send_page.dart` | **Improvement 1:** Removed the legacy "Nearby devices" UI section (`DeviceRadar`, heading, subtitle, empty state, "Can't see it? Get help" action) while preserving Direct Link, QR Scanner, staged files list, Clear button, and "Send a message instead". |
| `lib/core/monitoring/observed_traffic.dart` | **Improvement 3:** Added `DeviceTrafficRecord` model and per-device traffic accounting engine. Tracks Rx/Tx bytes, completed file counts, text message counts, and last seen timestamps. Implemented persistence across app restarts via `SharedPreferences` and explicit user reset functionality. |
| `lib/core/transfer/receiver.dart` | **Improvement 3:** Attached `ObservedTraffic.instance.recordLanLinkTransfer` to incoming LanLink protocol transfers, extracting peer IP from client sessions. |
| `lib/core/models/active_client.dart` | **Improvement 2:** Allowed mutable `hostname` field to permit asynchronous reverse DNS lookup enrichment. |
| `lib/state/app_state.dart` | **Improvements 2 & 3:** Added Windows ARP cache scanning integration (`getMacForIp`), reverse DNS lookup cache, outgoing LanLink transfer traffic accounting (`recordOutgoingTransfer`), and loaded persisted device traffic on startup `bootstrap()`. |
| `lib/ui/shell/home_page.dart` | **Improvements 2, 3, 4:** Replaced the previous peer list with the comprehensive **Connected Hotspot Devices** section. Added two-tier device categorization, live RTT ping triggers, MAC address display, Observed App Data metric, Send Message dialog with validation, instant feedback SnackBars, and Activity Journal logging. |
| `lib/core/web/web_portal.dart` | Cleaned up unused import. |
| `test/observed_traffic_test.dart` | Added automated unit test suite verifying `DeviceTrafficRecord` calculations, JSON serialization, `ObservedTraffic` metrics, `SharedPreferences` persistence, and reset functionality. |

---

## 3. UI Changes Made

### Improvement 1: Send Page Streamlining
- **Removed:**
  - "Nearby devices" section header.
  - "Tap a device to choose files and send" subtitle.
  - `DeviceRadar` animated widget and associated peer avatar layout.
  - "No devices found yet" empty state message.
  - "Can't see it? Get help" action button.
- **Preserved:**
  - File staging tray with thumbnails, file sizes, category icons, and "Clear" button.
  - "Send a message instead" modal toggle.
  - Direct Link IPv4 / hostname connection dialog.
  - QR Code scanner interface for direct pairing.

### Improvement 2 & 4: Dashboard — "Connected Hotspot Devices"
- **New Section Header:** "CONNECTED HOTSPOT DEVICES" featuring:
  - Live device count counter badge.
  - Manual **Refresh** button triggering both LanLink mDNS/Subnet scan and Windows ARP table polling.
  - Animated progress indicator displayed during active scans.
  - "Direct Link" shortcut button.
  - Prominent architectural note explaining mobile hotspot gateway constraints.
- **Two-Tier Device Classification:**
  1. **Tier 1 — Compatible Hotspot Guardian Receivers:**
     - Device alias and model (e.g., `Marmalade-Fox (Windows / PC)`).
     - Local IPv4 address and port (e.g., `192.168.43.150:53317`).
     - Layer 2 MAC address resolved via Windows ARP cache.
     - Live connection status with measured RTT latency (e.g., `Active • 12 ms RTT`) and latency refresh button.
     - Application-observed data metrics (e.g., `Observed App: 4.25 MB (Rx: 4.25 MB, Tx: 0.00 MB) • Total WAN: Not measurable`).
     - Relative last activity timestamp (e.g., `2m ago`).
     - **Send Message** action button.
     - **Send File** action button.
  2. **Tier 2 — Observed Local Network Devices (ARP / Gateway):**
     - Hostname resolved via reverse DNS or NetBIOS/DNS (e.g., `phone-hotspot.lan`, or `Unknown (No reverse DNS)`).
     - Local IPv4 address (e.g., `192.168.43.1`).
     - Physical hardware MAC address (e.g., `38-F9-D3-XX-XX-XX`).
     - Status: `Observed on Subnet (No receiver detected)`.
     - Observed Web Portal data if the client used the browser portal, or `0.00 MB (Observed App) • Total WAN: Not measurable`.
     - Last seen timestamp.
     - Disabled `Messaging Unsupported` badge clearly stating that messaging requires an active receiver.
- **Empty State:**
  - Informative card explaining that no local devices or receivers were observed yet, providing troubleshooting guidance and a "Scan Now" button.

### Improvement 4: Host-to-Device Messaging Action
- Clicking **Send Message** on a compatible receiver opens an interactive dialog:
  - Displays target device alias, IP address, and port.
  - Multiline message text input field.
  - Action buttons: "Cancel" and "Send".
- Real-time feedback:
  - Green SnackBar on successful delivery: `Message delivered to <alias>`.
  - Red SnackBar on failure/timeout: `Failed to deliver message: <error>`.
- Automated logging: Outcome recorded to the persistent **Activity Journal** (`EventLog`).

---

## 4. How Device Discovery Works

The application employs a layered discovery architecture optimized for Windows desktop:
1. **LanLink Compatible Receiver Discovery:**
   - **Subnet Port Scanner:** Probes active subnet IP ranges on Hotspot Guardian's receiver ports (`53317` and fallback ports) via HTTP `GET /info`. Responses provide device alias, OS type, device model, and protocol version.
   - **Multicast DNS / UDP Broadcast:** Listens for announcement packets broadcast by peers running the receiver service on the local network.
2. **Layer 2 Windows ARP Table Inspection (`ArpScanner`):**
   - Executes native Windows `arp -a` via `Process.run`.
   - Parses the output table mapping IPv4 addresses to physical MAC addresses.
   - Filters out loopback (`127.x.x.x`), multicast (`224.0.0.0`–`239.255.255.255`), and broadcast addresses (`255.255.255.255`).
3. **Reverse DNS Resolution:**
   - Asynchronously performs `InternetAddress.lookup(ip)` to query local DNS/mDNS/NetBIOS for hostnames corresponding to observed IP addresses.

---

## 5. Obtainable Device Details vs. Limitations

| Field | Availability | Source / Methodology |
|---|---|---|
| **Device Name / Alias** | Genuine | Discovered via `GET /info` for compatible receivers; reverse DNS lookup for general ARP devices. |
| **Local IPv4 Address** | Genuine | Socket peer address, HTTP request remote address, or ARP cache. |
| **MAC Address** | Genuine | Extracted directly from the Windows OS ARP neighbor cache (`arp -a`). |
| **Connection / Latency** | Genuine | Live ICMP/HTTP RTT latency measurement (`/ping` endpoint) for receivers; ARP presence for other devices. |
| **Last Seen Time** | Genuine | Monitored timestamp of last socket handshake, ping, or HTTP transaction. |
| **Total Cellular / WAN Hotspot Usage** | **Not Measurable** | **Physically inaccessible on a client device** (see Section 6). |
| **Hotspot Guardian Observed Data** | Genuine | Precise byte counts tracked during Web Portal transfers and LanLink protocol sessions. |

---

## 6. Per-Device Hotspot Data Usage: Physical Constraint & Solution

### Architectural Constraint
In this project setup, the Windows laptop is a Wi-Fi client (Station / STA) connected to a smartphone's Wi-Fi hotspot (Access Point / Router / AP). 
- Network packets sent between another hotspot client (e.g., another smartphone) and the Internet travel directly through the phone's Wi-Fi AP and cellular radio (WAN interface).
- Because 802.11 Wi-Fi frames in infrastructure mode are unicast to the AP, **third-party Internet traffic never traverses the Windows laptop's network interface card**.
- Promiscuous packet sniffing (even with Npcap/WinPcap) cannot capture unicast wireless frames encrypted with WPA2-PSK destined for other stations.
- Mobile hotspot routers (iOS / Android) do not expose SNMP, NetFlow, or DHCP lease traffic accounting APIs to connected clients.

### Implemented Solution: Hotspot Guardian Observed Data
To maintain strict technical integrity and avoid fabricating numbers:
1. The dashboard explicitly labels all metrics as:
   `Observed App: X.XX MB • Total WAN: Not measurable`
2. An explanatory callout on the dashboard informs the user:
   > *"Gateway Architecture Note: Mobile hotspot gateways (phones) do not expose client lists or WAN usage to connected devices. Below are peers running Hotspot Guardian and devices detected on the local subnet via ARP."*
3. The application accurately tracks and persists:
   - Bytes received via the local Web Portal (uploads + messages).
   - Bytes received via the LanLink peer-to-peer receiver (files + messages).
   - Bytes sent to peers via Hotspot Guardian (outgoing file transfers + messages).
   - Counts of completed files and messages.
   - Timestamps of most recent activity.
4. Data is stored persistently in `SharedPreferences` under `hotspot_guardian_device_traffic_v1` and can be reset on demand.

---

## 7. Messaging Capabilities & Limitations

### Capabilities
- The host laptop can select any compatible Hotspot Guardian receiver from the dashboard and click **Send Message**.
- A text payload is created, validated, and transmitted over the secure HTTP/HTTPS peer endpoint.
- Immediate UI feedback (green success or red failure SnackBar) is provided.
- Every send attempt, success, and failure is permanently logged in the **Activity Journal**.
- Existing browser-to-host messaging via the Web Portal (`/api/message`) remains fully operational.

### Limitations
- **Standard ARP clients / Web browsers:** Ordinary phones or laptops without a background Hotspot Guardian receiver process do not listen on TCP port `53317`. The UI identifies these as "Observed on Subnet" and displays a disabled `Messaging Unsupported` badge, preventing futile socket connection attempts.
- **Web Portal clients:** A client browsing the Web Portal can push messages *to* the host laptop, but cannot receive push messages unless an active receiver app is running on their device.

---

## 8. Verification and Test Results

### 1. Static Analysis (`dart analyze`)
- Analyzed all modified application code and test suites:
  - **Result:** `0 errors`, `0 warnings`. (All 34 remaining `info` issues are pre-existing Flutter 3.27+ framework deprecation notices in untouched legacy code).

### 2. Automated Unit Tests
- `test/observed_traffic_test.dart` (New suite):
  - `DeviceTrafficRecord initializes with zeros and calculates MB`: **PASSED**
  - `DeviceTrafficRecord serializes and deserializes correctly`: **PASSED**
  - `ObservedTraffic Service records web uploads and messages`: **PASSED**
  - `ObservedTraffic Service records outgoing LanLink file transfers and messages`: **PASSED**
  - `ObservedTraffic Service persists to and restores from SharedPreferences`: **PASSED**
  - `ObservedTraffic Service reset clears all in-memory and persistent records`: **PASSED**
  - **Result:** **6/6 tests passed**.
- `test/event_log_test.dart`:
  - `records entries and exports them oldest-first`: **PASSED**
  - `ring buffer caps at maxEntries, dropping the oldest`: **PASSED**
  - `clear empties the buffer`: **PASSED**
  - **Result:** **3/3 tests passed**.
- `test/text_payload_test.dart`:
  - `stages a snippet as a real .txt with matching metadata`: **PASSED**
  - `unicode snippets round-trip byte-exact`: **PASSED**
  - `file name contains no path-hostile characters`: **PASSED**
  - **Result:** **3/3 tests passed**.

---

## 9. Remaining Architectural Limitations
1. **Third-Party Internet Accounting:** As detailed in Section 6, measuring total mobile hotspot data consumed by external devices requires custom firmware or metering software installed directly on the smartphone/router gateway.
2. **Reverse DNS on Mobile Hotspots:** Mobile phone hotspots rarely run local NetBIOS or mDNS resolver proxies for connected clients; as a result, non-receiver ARP clients typically show their IP and MAC address, with hostnames marked as "Unknown (No reverse DNS)".
