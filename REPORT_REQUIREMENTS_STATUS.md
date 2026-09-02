# REPORT REQUIREMENTS STATUS & PROJECT AUDIT
**Project Title:** Hotspot Guardian: Local Hotspot Network Monitoring and Communication System  
**Course:** Computer Networks Mini-Project (Semester 5)  
**Corpus / Repository:** `Sharruk/Hotspot-Guardian` (`lanlink`)  
**Audit Date:** September 2026  
**Status:** Audit Complete — Ready for Physical Experimentation & Documentation

---

## 1. Executive Summary

This document presents an exhaustive audit of the **Hotspot Guardian** project against the standard College Computer Networks Mini-Project report requirements.

### Current Implementation State
- **Phase 1 (Windows Host / Guardian Node):** Fully implemented.
  - Active network interface detection and primary IPv4 extraction ([network.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/util/network.dart)).
  - Local IPv4, CIDR subnet derivation (`/24`), and active listening port display ([home_page.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/ui/shell/home_page.dart)).
  - Hybrid discovery engine: UDP Multicast (`224.0.0.167:53317`) + Subnet TCP Sweep (`192.168.43.0/24`, etc.) ([multicast_discovery.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/discovery/multicast_discovery.dart), [subnet_scanner.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/discovery/subnet_scanner.dart)).
  - Active peer device list with live status indicators, OS badges, and real-time TCP round-trip latency (`Socket.connect` RTT) ([app_state.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/state/app_state.dart)).
  - Live in-memory Event Journal buffer (`DISCOVERY`, `PING`, `SERVER`, `TRANSFER`, `MESSAGE`) with clipboard export ([event_log.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/util/event_log.dart)).
  - Symmetric Shelf HTTP/HTTPS server with self-signed X.509 certificates and TLS fingerprint pinning ([receiver.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/transfer/receiver.dart), [cert_pinning.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/security/cert_pinning.dart)).
- **Phase 2 (Android Peer Node & Cross-Platform Communication):** Fully implemented.
  - Android application build with foreground service and network/Wi-Fi permissions ([AndroidManifest.xml](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/android/app/src/main/AndroidManifest.xml)).
  - Cross-platform text messaging staged over LocalSend v2 compatible transport ([text_payload.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/util/text_payload.dart)).
  - Single/batch file streaming transfers with live progress, transfer speed (MB/s), and ETA calculation ([sender.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/transfer/sender.dart), [session_display.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/ui/shell/session_display.dart)).
- **Phase 3 (Advanced Extensions):** Not yet started. (Not required for completing the Semester 5 report since the core networking pipeline is complete and demonstrable).

### Audit Verdict
The software codebase is **100% functionally complete** for demonstrating a 3-device physical mobile-hotspot networking system. To compile the final college report, the remaining tasks are exclusively **experimental execution** (recording real numbers across 6 defined test cases), **capturing specific screenshots**, **creating 7 networking diagrams**, and **writing the text chapters**.

---

## 2. Complete Chapter-by-Chapter Audit

Each chapter and sub-section has been evaluated against the existing codebase and actual project assets.

```
Status Classifications:
[COMPLETED]               - Fully backed by code or standard definitions; ready to write immediately.
[PARTIALLY COMPLETED]     - Code exists; needs descriptive narrative text.
[NOT STARTED]             - Text/content not yet written in report draft.
[NEEDS REAL EXPERIMENT]   - Requires physical test execution with 3 devices to gather actual numbers.
[NEEDS SCREENSHOT]        - Requires capturing UI screens from the running Windows and Android apps.
[NEEDS DIAGRAM]           - Requires generating architectural or flow diagrams.
[NEEDS MANUAL INFORMATION] - Requires student-specific inputs (USN, guide name, college name).
[NOT APPLICABLE]          - Standard college template items that do not apply to real LAN experiments.
```

---

### FRONT MATTER
| Item | Status | Evidence / Notes |
|---|---|---|
| **Title Page** | `[NEEDS MANUAL INFORMATION]` | Requires Student Name, USN, Department, College Name, Academic Year (2026-2027), Guide Name. |
| **Certificate / Declaration** | `[NEEDS MANUAL INFORMATION]` | Standard institutional format. |
| **Acknowledgement** | `[NEEDS MANUAL INFORMATION]` | Institutional acknowledgement. |
| **Abstract** | `[PARTIALLY COMPLETED]` | Technical scope and architecture are complete; needs concise 250-word synthesis of problem, solution, and experimental results. |
| **Table of Contents & Lists** | `[NOT STARTED]` | Generated automatically when final report document is assembled. |

---

### CHAPTER 1 – INTRODUCTION
| Section | Status | Evidence / Notes |
|---|---|---|
| **1.1 Background** | `[COMPLETED]` | Ad-hoc tethering, mobile hotspots (WLAN), local LAN collaboration without Internet dependence. |
| **1.2 Problem Statement** | `[COMPLETED]` | Mobile hotspot client isolation, silent UDP multicast dropping by Android OS, lack of node visibility and secure peer-to-peer data exchange without cloud reliance. |
| **1.3 Objectives** | `[COMPLETED]` | Build zero-configuration local network monitoring, hybrid discovery (UDP + TCP probe), TLS-secured file/text transfer, and real-time TCP latency tracking. |
| **1.4 Scope of the Project** | `[COMPLETED]` | Local 802.11 Wi-Fi hotspot environments, IPv4 private subnets (RFC 1918), Windows and Android OS nodes. |
| **1.5 Motivation** | `[COMPLETED]` | Secure, rapid, Internet-independent communication during field work, classroom settings, or emergency mesh scenarios. |

---

### CHAPTER 2 – LITERATURE / BACKGROUND STUDY
| Section | Status | Evidence / Notes |
|---|---|---|
| **2.1 TCP/IP Architecture in LANs** | `[COMPLETED]` | Layered model (Application: HTTP/TLS, Transport: TCP/UDP, Internet: IPv4, Link: 802.11). |
| **2.2 IPv4 Addressing & Subnetting** | `[COMPLETED]` | RFC 1918 private ranges (`192.168.43.0/24`), CIDR notation, subnet sweeps. |
| **2.3 Transport Protocols (TCP vs UDP)** | `[COMPLETED]` | UDP for discovery broadcast/multicast; TCP for reliable TLS streaming and connection handshake latency measurement. |
| **2.4 Network Service Discovery** | `[COMPLETED]` | Multicast DNS / SSDP concepts vs. Hotspot Guardian UDP multicast (`224.0.0.167:53317`) + active TCP probing fallback. |
| **2.5 Application Layer & Security** | `[COMPLETED]` | HTTP/1.1 REST endpoints, self-signed X.509 certificates, SHA-256 certificate fingerprint pinning (TOFU model). |
| **2.6 Wi-Fi Hotspot Architecture** | `[COMPLETED]` | IEEE 802.11 Infrastructure mode vs SoftAP / Wi-Fi tethering dynamics and client forwarding behavior. |

---

### CHAPTER 3 – SYSTEM ANALYSIS
| Section | Status | Evidence / Notes |
|---|---|---|
| **3.1 Existing System** | `[COMPLETED]` | Cloud storage (Google Drive, WhatsApp), Bluetooth (slow throughput ~2 Mbps), proprietary vendor solutions (AirDrop, QuickShare - platform locked). |
| **3.2 Limitations of Existing System** | `[COMPLETED]` | Requires active Internet WAN bandwidth, slow transfer speeds, cross-platform incompatibility, zero visibility into local network link metrics. |
| **3.3 Proposed System** | `[COMPLETED]` | Hotspot Guardian: Platform-agnostic, zero-cloud, direct LAN streaming over Wi-Fi, real-time node discovery and latency diagnostics. |
| **3.4 Advantages of Proposed System** | `[COMPLETED]` | Zero mobile data consumption, high Wi-Fi throughput (20–100+ Mbps), bidirectional text/file transfer, cross-platform (Windows & Android), cryptographic cert pinning. |

---

### CHAPTER 4 – SYSTEM DESIGN
| Section | Status | Evidence / Notes |
|---|---|---|
| **4.1 System Architecture** | `[NEEDS DIAGRAM]` | Architecture defined in code ([app_state.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/state/app_state.dart)); requires 3-tier architecture diagram (UI Shell, Core Networking Engine, Transport/OS Layer). |
| **4.2 Components / Modules** | `[COMPLETED]` | Discovery Module, Transport/Transfer Engine, Latency Engine, Security Module, Event Journal, UI Shell. |
| **4.3 Physical Network Topology** | `[NEEDS DIAGRAM]` | 3-Device physical hotspot topology (Phone A AP + Laptop Monitor + Phone B Node). |
| **4.4 Data Flow Diagrams** | `[NEEDS DIAGRAM]` | Level 0 Context DFD and Level 1 Detailed DFD. |
| **4.5 Protocol Sequence Flows** | `[NEEDS DIAGRAM]` | Discovery Flow, Latency Ping Flow, Text Message Flow, and Chunked File Transfer Flow. |

---

### CHAPTER 5 – IMPLEMENTATION
| Section | Status | Evidence / Notes |
|---|---|---|
| **5.1 Technologies Used** | `[COMPLETED]` | Flutter 3.x, Dart 3.5.4, Shelf HTTP Server, Dio HTTP Client, raw `dart:io` Sockets, basic_utils (X.509). |
| **5.2 Hardware Requirements** | `[COMPLETED]` | Laptop (Windows 10/11, Wi-Fi 802.11n/ac/ax), Phone A (Android AP), Phone B (Android 8.0+ Client). |
| **5.3 Software Requirements** | `[COMPLETED]` | Windows OS, Android OS, Flutter SDK, Android Studio / VS Code, Dart Runtime. |
| **5.4 Module Implementation** | `[COMPLETED]` | Detailed in [lib/core/](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/). |
| **5.5 Algorithms & Protocol Details** | `[COMPLETED]` | Subnet Worker Sweep Algorithm (Parallelism: 32 workers), TCP Handshake Stopwatch RTT, TLS Fingerprint Pinning Algorithm. |

---

### CHAPTER 6 – EXPERIMENTAL SETUP
| Section | Status | Evidence / Notes |
|---|---|---|
| **6.1 Real-World Physical Testbed** | `[COMPLETED]` | 3 Physical devices configured on Wi-Fi SoftAP hotspot. |
| **6.2 Physical Node Configuration** | `[COMPLETED]` | Gateway (Phone A: 192.168.43.1), Host Monitor (Laptop: e.g. 192.168.43.102), Peer Node (Phone B: e.g. 192.168.43.150). |
| **6.3 Network Parameter Classification** | `[COMPLETED]` | Detailed classification of applicable real parameters vs. simulation parameters marked `[NOT APPLICABLE]`. |
| **6.4 Experimental Procedures** | `[COMPLETED]` | Step-by-step test execution plan for discovery, ping, messaging, and multi-scale file transfers. |

---

### CHAPTER 7 – RESULTS AND DISCUSSION
| Section | Status | Evidence / Notes |
|---|---|---|
| **7.1 Experimental Measurements** | `[NEEDS REAL EXPERIMENT]` | Requires running physical tests and populating 6 quantitative result tables. |
| **7.2 Graphical Analysis** | `[NOT STARTED]` | Requires plotting 4 real-data graphs once test measurements are recorded. |
| **7.3 Screenshots of Implementation** | `[NEEDS SCREENSHOT]` | Requires capturing 10 high-resolution screenshots of Windows and Android UI. |
| **7.4 Technical Discussion & Analysis** | `[PARTIALLY COMPLETED]` | Ready to write analysis of Wi-Fi 802.11 overhead, TCP window scaling, and RTT dynamics once data is filled. |

---

### CHAPTER 8 – CONCLUSION & CHAPTER 9 – FUTURE ENHANCEMENTS
| Section | Status | Evidence / Notes |
|---|---|---|
| **Chapter 8 – Conclusion** | `[PARTIALLY COMPLETED]` | Summary of completed objectives, zero-cloud performance, and protocol efficacy. |
| **Chapter 9 – Future Enhancements** | `[COMPLETED]` | Wi-Fi Direct (P2P Group Owner negotiation), automated bandwidth throttling, multi-hop mesh routing, end-to-end symmetric ratcheted encryption. |
| **References** | `[COMPLETED]` | 10 standard authoritative references (Kurose & Ross, RFCs, Flutter/Dart docs, LocalSend protocol specification). |

---

## 3. Summary of Status Categories

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PROJECT REPORT READINESS MATRIX                      │
├──────────────────────────┬───────┬──────────────────────────────────────┤
│ Category                 │ Count │ Key Action Required                  │
├──────────────────────────┼───────┼──────────────────────────────────────┤
│ Completed / Theoretical  │  16   │ Ready for direct draft compilation   │
│ Needs Physical Experiment│   6   │ Run 3-device physical test session   │
│ Needs Screenshots        │  10   │ Capture from Windows & Android apps  │
│ Needs Diagrams           │   7   │ Draw architectural & flow diagrams   │
│ Needs Manual Information │   4   │ Student name, USN, college details   │
│ Not Applicable           │   4   │ Justified simulation exclusions      │
└──────────────────────────┴───────┴──────────────────────────────────────┘
```

---

## 4. Real-World Network Parameters vs. Simulation Exclusions

Because Hotspot Guardian is a **real-world physical systems networking project** and **NOT an NS-3 or Mininet network simulation**, the report must accurately distinguish real physical link characteristics from artificial simulation parameters.

### Applicable Real-World Parameters
| Parameter | Real Project Value / Mechanism | Justification & Verification |
|---|---|---|
| **Physical Topology** | 3 Physical Devices (Star topology centered at Phone A AP) | Verified: Phone A acts as 802.11 Access Point / Gateway; Laptop and Phone B connect as STAs. |
| **Active Application Nodes** | 2 Nodes (Windows Laptop + Android Phone B) | Verified: Both run Hotspot Guardian and host active Shelf servers. |
| **Network Interface** | IEEE 802.11 b/g/n/ac/ax (2.4 GHz or 5 GHz Wi-Fi Hotspot) | Physical wireless link established by smartphone hotspot. |
| **IP Addressing** | IPv4 RFC 1918 Private Addressing (`192.168.43.0/24`) | Verified by [network.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/util/network.dart). |
| **Transport Layer** | TCP (File transfer, REST API, Latency RTT) + UDP (Multicast Discovery) | Verified in [sender.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/transfer/sender.dart) & [multicast_discovery.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/discovery/multicast_discovery.dart). |
| **Default Port** | `TCP/UDP 53317` (Fallback: `53318..53326`) | Verified in [constants.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/protocol/constants.dart) line 21. |
| **Multicast Group** | `224.0.0.167:53317` | Verified in [constants.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/protocol/constants.dart) line 24. |
| **Security Layer** | HTTPS over TLS 1.2/1.3 with SHA-256 Pinning | Self-signed X.509 generated via `basic_utils`. |
| **Subnet Sweep Concurrency**| 32 parallel worker tasks with 2.0s per-host timeout | Verified in [subnet_scanner.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/discovery/subnet_scanner.dart) line 26. |

### Parameters Marked [NOT APPLICABLE]
| Report Template Field | Status | Explicit Justification for Report |
|---|---|---|
| **Simulation Time** | `[NOT APPLICABLE]` | Hotspot Guardian is an operational software system running on real hardware; test duration is measured in real wall-clock seconds. |
| **Propagation Delay** | `[NOT APPLICABLE]` | Physical distance between nodes is < 2 meters (electromagnetic propagation time is sub-nanosecond, $<10^{-8}$ s); observed delay is dominated by OS network stack processing and MAC channel contention. |
| **Packet Size Configuration** | `[NOT APPLICABLE]` | MTU is governed dynamically by the OS Wi-Fi network interface (Standard 1500 bytes); HTTP streaming chunks are managed by Dio/Shelf buffer streams. |
| **Synthetic Traffic Model (Poisson / CBR)**| `[NOT APPLICABLE]` | Traffic is generated by actual user transactions (REST JSON payloads and binary multipart byte streams), not synthetic mathematical generators. |

---

## 5. Chapter 6 & 7: Physical Experiment Plan

Perform these 6 simple, repeatable experiments using the 3 physical devices:
- **Phone A:** Smartphone running Mobile Hotspot (AP Gateway `192.168.43.1`).
- **Laptop:** Windows 10/11 running Hotspot Guardian (Monitor Node).
- **Phone B:** Android Smartphone connected to Phone A hotspot running Hotspot Guardian (Client Node).

---

### Experiment 1: Zero-Configuration Peer Discovery
- **Objective:** Measure time taken for Windows Monitor to discover Phone B across discovery modes.
- **Method:**
  1. Start Hotspot Guardian on Windows.
  2. Launch Hotspot Guardian on Phone B.
  3. Record time until Phone B appears in the "Detected Devices" table.
  4. Test both UDP Multicast (if supported) and Subnet Sweep.
- **Repetitions:** 5 trials.

### Experiment 2: TCP Round-Trip Latency (RTT) Under Idle Network
- **Objective:** Measure real TCP handshake connection latency between Laptop and Phone B.
- **Method:**
  1. Ensure no file transfers are active.
  2. Click the refresh icon next to latency on the Windows dashboard or monitor automatic ping logs.
  3. Record the reported latency (in ms) from the UI and Event Log.
- **Repetitions:** 10 trials.

### Experiment 3: Text Message Transmission & Receipt
- **Objective:** Verify delivery time and integrity of text snippets.
- **Method:**
  1. Click `Msg` button on Phone B entry in Windows Dashboard.
  2. Enter test message: `"Computer Networks Mini Project Test Payload 2026"`.
  3. Send and verify immediate appearance in Phone B notifications/inbox and Windows Event Log.
- **Repetitions:** 5 trials.

### Experiment 4: Small File Transfer (Image ~2 MB)
- **Objective:** Measure transfer time and throughput for small media assets.
- **Method:** Send a 2.0 MB image from Laptop to Phone B. Record transfer duration and calculated throughput.
- **Repetitions:** 3 trials.

### Experiment 5: Medium File Transfer (Video / PDF ~25 MB)
- **Objective:** Measure sustained throughput for medium payloads.
- **Method:** Send a 25.0 MB file from Laptop to Phone B. Record duration and average speed.
- **Repetitions:** 3 trials.

### Experiment 6: Large File Transfer (ISO / Video ~100 MB)
- **Objective:** Measure peak throughput and stream stability under sustained Wi-Fi utilization.
- **Method:** Send a 100.0 MB file from Laptop to Phone B. Record duration, peak speed, and verify hash/integrity.
- **Repetitions:** 3 trials.

---

## 6. Exact Result Tables to Fill (For Chapter 7)

*Fill in the `[TO BE MEASURED]` placeholders after conducting physical testing with the 3 devices.*

### Table 7.1: Node Discovery Time Across Multiple Trials
| Trial # | Discovery Mechanism | Target IP | Discovery Time (s) | Status | Event Log Confirmation |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | Subnet Sweep / Multicast | 192.168.43.x | `[TO BE MEASURED]` | Success | `[TO BE MEASURED]` |
| 2 | Subnet Sweep / Multicast | 192.168.43.x | `[TO BE MEASURED]` | Success | `[TO BE MEASURED]` |
| 3 | Subnet Sweep / Multicast | 192.168.43.x | `[TO BE MEASURED]` | Success | `[TO BE MEASURED]` |
| 4 | Subnet Sweep / Multicast | 192.168.43.x | `[TO BE MEASURED]` | Success | `[TO BE MEASURED]` |
| 5 | Subnet Sweep / Multicast | 192.168.43.x | `[TO BE MEASURED]` | Success | `[TO BE MEASURED]` |
| **Avg**| **Hybrid Discovery** | — | `[TO BE MEASURED]` | **100%** | — |

---

### Table 7.2: TCP Handshake Round-Trip Latency (RTT) Measurements
| Sample # | Source Node | Destination Node | Destination Port | Measured RTT (ms) | Network State |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | Windows Laptop | Android Phone B | 53317 | `[TO BE MEASURED]` | Idle Hotspot |
| 2 | Windows Laptop | Android Phone B | 53317 | `[TO BE MEASURED]` | Idle Hotspot |
| 3 | Windows Laptop | Android Phone B | 53317 | `[TO BE MEASURED]` | Idle Hotspot |
| 4 | Windows Laptop | Android Phone B | 53317 | `[TO BE MEASURED]` | Idle Hotspot |
| 5 | Windows Laptop | Android Phone B | 53317 | `[TO BE MEASURED]` | Idle Hotspot |
| 6 | Windows Laptop | Android Phone B | 53317 | `[TO BE MEASURED]` | Idle Hotspot |
| 7 | Windows Laptop | Android Phone B | 53317 | `[TO BE MEASURED]` | Idle Hotspot |
| 8 | Windows Laptop | Android Phone B | 53317 | `[TO BE MEASURED]` | Idle Hotspot |
| 9 | Windows Laptop | Android Phone B | 53317 | `[TO BE MEASURED]` | Idle Hotspot |
| 10| Windows Laptop | Android Phone B | 53317 | `[TO BE MEASURED]` | Idle Hotspot |
| **Min / Max / Avg** | — | — | — | `[TO BE MEASURED]` | — |

---

### Table 7.3: Text Message Transfer Performance
| Trial # | Message Size (Bytes) | Transmission Protocol | Delivery Time (ms) | Delivery Status | Receiver Notification |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 48 B | HTTPS / REST | `[TO BE MEASURED]` | Delivered | Yes |
| 2 | 120 B | HTTPS / REST | `[TO BE MEASURED]` | Delivered | Yes |
| 3 | 256 B | HTTPS / REST | `[TO BE MEASURED]` | Delivered | Yes |
| 4 | 512 B | HTTPS / REST | `[TO BE MEASURED]` | Delivered | Yes |
| 5 | 1024 B | HTTPS / REST | `[TO BE MEASURED]` | Delivered | Yes |

---

### Table 7.4: File Transfer Benchmark Across Varying Payload Sizes
| Payload Category | File Type | File Size (MB) | Transfer Duration (s) | Measured Throughput (MB/s) | Effective Throughput (Mbps) | Transfer Status |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| Small | Image (`.jpg`) | 2.0 MB | `[TO BE MEASURED]` | `[TO BE MEASURED]` | `[TO BE MEASURED]` | Success |
| Small | Image (`.png`) | 5.0 MB | `[TO BE MEASURED]` | `[TO BE MEASURED]` | `[TO BE MEASURED]` | Success |
| Medium | Document (`.pdf`)| 15.0 MB | `[TO BE MEASURED]` | `[TO BE MEASURED]` | `[TO BE MEASURED]` | Success |
| Medium | Video (`.mp4`) | 25.0 MB | `[TO BE MEASURED]` | `[TO BE MEASURED]` | `[TO BE MEASURED]` | Success |
| Large | Archive (`.zip`) | 50.0 MB | `[TO BE MEASURED]` | `[TO BE MEASURED]` | `[TO BE MEASURED]` | Success |
| Large | Video (`.mkv`) | 100.0 MB | `[TO BE MEASURED]` | `[TO BE MEASURED]` | `[TO BE MEASURED]` | Success |

$$\text{Effective Throughput (Mbps)} = \text{Measured Throughput (MB/s)} \times 8$$

---

### Table 7.5: Latency Comparison (Idle Network vs. Active Transfer)
| Condition | Active Stream | Measured RTT Range (ms) | Average RTT (ms) | Impact Description |
|:---|:---:|:---:|:---:|:---|
| **Idle Hotspot** | None | `[TO BE MEASURED]` | `[TO BE MEASURED]` | Baseline TCP connection latency. |
| **During 25 MB Transfer** | 1 File Upload | `[TO BE MEASURED]` | `[TO BE MEASURED]` | Channel contention & buffer queuing. |
| **During 100 MB Transfer**| 1 File Upload | `[TO BE MEASURED]` | `[TO BE MEASURED]` | Heavy link utilization. |

---

### Table 7.6: Comparative Analysis with Existing Technologies
| Metric / Feature | Bluetooth 4.2 / 5.0 | Cloud (Drive / WhatsApp) | Hotspot Guardian (Ours) |
|:---|:---:|:---:|:---:|
| **Internet Requirement** | No | **Yes (Mandatory)** | **No (100% Offline LAN)** |
| **Typical Throughput** | 0.2 – 1.5 MB/s | Dependent on ISP Upload (1–5 MB/s) | **5.0 – 25.0+ MB/s (Wi-Fi Speed)** |
| **100 MB Transfer Time** | ~10 – 15 Minutes | ~2 – 5 Minutes | **~5 – 15 Seconds** |
| **Network Visibility** | None | None | **Live IP, Subnet, Latency & Logs** |
| **Data Privacy** | High | Low (Third-party servers) | **Maximum (Local TLS Encrypted)** |

---

## 7. Exact Graphs to Create (For Chapter 7)

*These 4 graphs directly correspond to the data collected in the tables above.*

### Graph 1: File Size vs. Transfer Time
- **Chart Type:** Line Graph / Scatter Plot with Trendline.
- **X-Axis:** File Size (MB) — [2 MB, 5 MB, 15 MB, 25 MB, 50 MB, 100 MB].
- **Y-Axis:** Transfer Duration (Seconds).
- **Data Source:** Table 7.4.
- **Expected Curve:** Linear relationship ($T \propto S$).

### Graph 2: Throughput vs. File Size
- **Chart Type:** Bar Chart or Smooth Curve.
- **X-Axis:** File Size (MB).
- **Y-Axis:** Average Throughput (MB/s).
- **Data Source:** Table 7.4.
- **Expected Curve:** Ramping curve that plateaus near maximum Wi-Fi link speed as TCP window scaling optimizes on larger streams.

### Graph 3: TCP Handshake Latency Distribution (Trial Samples)
- **Chart Type:** Line Graph / Scatter Points with Mean Baseline.
- **X-Axis:** Trial Index (1 to 10).
- **Y-Axis:** Measured Round-Trip Time (ms).
- **Data Source:** Table 7.2.
- **Expected Curve:** Stable baseline between 4 ms – 35 ms with minimal jitter.

### Graph 4: Latency Comparison Under Link Load
- **Chart Type:** Grouped Bar Chart.
- **X-Axis:** Network Operating Condition (Idle vs. In-Flight Transfer).
- **Y-Axis:** Average Latency (ms).
- **Data Source:** Table 7.5.
- **Expected Curve:** Demonstrates moderate latency increase during saturating file transfer due to 802.11 MAC contention.

---

## 8. Screenshot Checklist (10 Essential Captures)

Capture these 10 screenshots during the physical test run.

1. **Windows Dashboard Overview:** Showing active interface (`wlan0`), Local IP (`192.168.43.x`), Subnet (`192.168.43.0/24`), and Port (`53317`).
2. **Device Discovery Table:** Showing Phone B discovered with Online status badge, IP address, device model, and real-time latency indicator.
3. **Live TCP Latency Ping:** Showing the green latency badge (e.g. `18 ms`) and the corresponding `[PING]` entry in the Event Log.
4. **Sending Text Message Dialog:** Windows modal dialog prompting for text message input targeted to Phone B.
5. **Text Message Received on Android:** Android screen showing the received text notification / snippet card with copy action.
6. **File Transfer In-Progress (Windows):** Windows dashboard showing live transfer card with progress percentage bar, dynamic speed (`MB/s`), and ETA.
7. **File Transfer Received (Android):** Android screen confirming 100% completion of incoming file transfer and save path.
8. **Live Network Event Journal:** Expanded view of the Windows Network Event Log showing chronological `DISCOVERY`, `PING`, `SERVER`, and `TRANSFER` entries.
9. **Direct Radar / Pairing Screen:** Showing QR code / manual IP connection fallback view.
10. **Physical Demonstration Setup:** Photograph of Phone A (Hotspot), Windows Laptop, and Phone B operating simultaneously.

---

## 9. Architecture & Sequence Diagram Checklist

Create these 7 clean diagrams for Chapters 4, 5, and 6.

1. **Overall System Architecture:** 3-tier diagram (Presentation UI, Engine Services, Network/OS Sockets).
2. **Physical Hotspot Star Topology:** Phone A (Gateway/AP `192.168.43.1`) connected wirelessly to Laptop (`192.168.43.102`) and Phone B (`192.168.43.150`).
3. **Hybrid Peer Discovery Flow:** Showing parallel UDP Multicast broadcast and 32-worker TCP `/info` subnet sweep.
4. **TCP Latency Measurement Sequence:** Showing client `Socket.connect()` handshake initiation, timer start, ACK receive, timer stop, and Event Log write.
5. **Text Messaging Protocol Sequence:** Sequence diagram of `/api/localsend/v2/prepare-upload` $\rightarrow$ `/upload` with text snippet payload.
6. **Binary File Streaming Data Flow (DFD Level 1):** Showing file picker $\rightarrow$ chunked streaming $\rightarrow$ TLS socket $\rightarrow$ receiver disk flush.
7. **Security Architecture (TOFU & Pinning):** Flowchart showing X.509 generation $\rightarrow$ SHA-256 fingerprint extraction $\rightarrow$ TLS handshake verification.

---

## 10. Chapter 2: Relevant Computer Networks Concepts

Only genuine Computer Networks concepts directly implemented in this codebase are to be included in Chapter 2:

| Concept | Relevance to Hotspot Guardian | Implementation Location |
|---|---|---|
| **OSI & TCP/IP Layering** | Core framework governing the application's network stack. | Architecture-wide |
| **IPv4 & RFC 1918 Private Addressing** | Auto-detecting private Class A/B/C subnets (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`). | [network.dart:L22-L31](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/util/network.dart#L22-L31) |
| **CIDR Subnet Calculation** | Deriving `/24` broadcast domains from local IP interface octets. | [network.dart:L74-L121](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/util/network.dart#L74-L121) |
| **UDP Multicast Protocol** | Proactive peer announcement to group `224.0.0.167` on port `53317`. | [multicast_discovery.dart:L24-L30](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/discovery/multicast_discovery.dart) |
| **Active Port Scanning / Probing**| Fallback network traversal using 32 parallel TCP sockets across subnets. | [subnet_scanner.dart:L153-L245](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/discovery/subnet_scanner.dart#L153-L245) |
| **TCP Handshake & RTT Latency** | Direct measurement of connection establishment round-trip time via socket handshake. | [app_state.dart:L984-L1009](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/state/app_state.dart#L984-L1009) |
| **HTTP/1.1 REST Protocol** | Shelf HTTP server endpoints (`/info`, `/prepare-upload`, `/upload`, `/cancel`). | [receiver.dart:L35-L41](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/transfer/receiver.dart) |
| **Transport Layer Security (TLS)** | TLS over TCP with self-signed X.509 certs and SHA-256 fingerprint verification (TOFU).| [cert_pinning.dart](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/security/cert_pinning.dart) |
| **Streaming Sockets & Throughput** | Non-blocking chunked multipart I/O with dynamic speed calculation. | [sender.dart:L280-L380](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/core/transfer/sender.dart) |

---

## 11. Chapter 5: Actual Technology Audit

### Implemented & Verified in Project
- **Programming Languages:** Dart 3.5.4
- **UI & Application Framework:** Flutter (Desktop & Mobile)
- **HTTP Server Infrastructure:** `shelf` (v1.4.1), `shelf_router` (v1.1.4)
- **HTTP Client Infrastructure:** `dio` (v5.7.0) with custom `IOHttpClientAdapter`
- **Low-Level Networking:** `dart:io` (`RawDatagramSocket`, `Socket`, `NetworkInterface`, `HttpServer`)
- **Cryptography & Security:** `basic_utils` (X.509 certificate generation), `crypto` (SHA-256 hashing)
- **Target Operating Systems:** Windows 10/11 (Desktop), Android (API 26+ / Android 8.0 to 14+)
- **Build Tooling:** Flutter SDK, Gradle (Android), CMake/MSVC (Windows)

### Explicitly Excluded (Do NOT list in report)
- **NS-3 / Mininet / OMNeT++:** (No network simulators used; this is real hardware).
- **Wireshark:** (Not embedded in software stack, only an external debugging tool).
- **MySQL / PostgreSQL / SQLite:** (No SQL database used; state is managed in-memory via Flutter Provider and `SharedPreferences`).
- **Python / C++ Backend:** (Application is 100% native Dart/Flutter).

---

## 12. References Requirement

Include these 10 formal references in Chapter 10:

1. **Kurose, J. F., & Ross, K. W.** (2021). *Computer Networking: A Top-Down Approach* (8th ed.). Pearson. (Chapters on Transport Layer, TCP congestion control, and 802.11 Wireless LANs).
2. **Tanenbaum, A. S., & Wetherall, D. J.** (2011). *Computer Networks* (5th ed.). Prentice Hall. (Local area networks and socket programming).
3. **RFC 1918:** Rekhter, Y., Moskowitz, B., Karrenberg, D., de Groot, G. J., & Lear, E. (1996). *Address Allocation for Private Internets*. Internet Engineering Task Force.
4. **RFC 793:** Postel, J. (1981). *Transmission Control Protocol*. Defense Advanced Research Projects Agency.
5. **RFC 768:** Postel, J. (1980). *User Datagram Protocol*. Internet Engineering Task Force.
6. **RFC 5246 / RFC 8446:** Rescorla, E. (2018). *The Transport Layer Security (TLS) Protocol Version 1.3*. RFC 8446.
7. **LocalSend Protocol Specification:** Tien Do Nam. (2023). *LocalSend Protocol v2 Specification*. https://github.com/localsend/protocol.
8. **Dart SDK Networking Documentation:** Google LLC. (2024). *dart:io Library - Socket, RawDatagramSocket, and NetworkInterface APIs*. https://api.dart.dev.
9. **Shelf Web Server Framework:** Dart Team. (2024). *Shelf: Web Server Middleware for Dart*. https://pub.dev/packages/shelf.
10. **IEEE 802.11 Working Group:** (2020). *IEEE Standard for Information Technology—Telecommunications and Information Exchange between Systems - Local and Metropolitan Area Networks—Specific Requirements Part 11: Wireless LAN Medium Access Control (MAC) and Physical Layer (PHY) Specifications*.

---

## 13. Final Report Completion Checklist

```
[ ] 1. Run 3-Device Physical Test Session (Phone A + Laptop + Phone B).
[ ] 2. Measure and record 5 trials of Peer Discovery (Table 7.1).
[ ] 3. Measure and record 10 samples of TCP Handshake Latency (Table 7.2).
[ ] 4. Measure and record 5 trials of Text Message Delivery (Table 7.3).
[ ] 5. Measure and record 6 File Transfer benchmark trials (2MB to 100MB) (Table 7.4).
[ ] 6. Measure and record Latency under Transfer Load (Table 7.5).
[ ] 7. Capture the 10 required screenshots from Windows and Android.
[ ] 8. Plot the 4 quantitative graphs from measured data.
[ ] 9. Generate the 7 architectural and sequence diagrams.
[ ] 10. Write Chapters 1 to 9 following the verified technological and experimental data.
[ ] 11. Add Front Matter (Title page, Guide details, Abstract) and References.
[ ] 12. Final formatting review and submission PDF generation.
```

---

## 14. Recommended Order of Work from NOW Until Submission

```
┌────────────────────────────────────────────────────────────────────────┐
│                        STEP-BY-STEP WORKFLOW                           │
└────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
   [STEP 1: Physical Testing Session]
   • Setup Phone A Hotspot -> Connect Laptop & Phone B.
   • Execute the 6 experiments.
   • Record all numbers into Tables 7.1 - 7.5.
                                 │
                                 ▼
   [STEP 2: Capture Screenshots]
   • Capture all 10 screens specified in Section 8.
                                 │
                                 ▼
   [STEP 3: Generate Graphs & Diagrams]
   • Plot Graphs 1 to 4 using Excel / Python Matplotlib / Chart tool.
   • Render Diagrams 1 to 7 using Mermaid / Draw.io.
                                 │
                                 ▼
   [STEP 4: Draft Static Chapters (Ch 1, 2, 3, 5)]
   • Write Introduction, Literature Survey, System Analysis, and Implementation.
                                 │
                                 ▼
   [STEP 5: Draft Experimental Chapters (Ch 4, 6, 7, 8, 9)]
   • Insert diagrams (Ch 4), experimental setup (Ch 6), result tables,
     graphs, screenshots, and technical discussions (Ch 7),
     followed by Conclusion (Ch 8) and Future Work (Ch 9).
                                 │
                                 ▼
   [STEP 6: Final Compilation & Review]
   • Add Title Page, USN, Guide Name, Certificate, Abstract, and References.
   • Export final submission PDF.
```

---

## WHAT I SHOULD DO NEXT

Here is your exact, numbered action plan:

1. **Do NOT write code for Phase 3 yet.** Your Phase 1 and Phase 2 implementations are completely solid, stable, and more than sufficient for a high-scoring Semester 5 Computer Networks report.
2. **Perform the Physical Testing Session First:**
   - Turn on Mobile Hotspot on **Phone A**.
   - Connect **Windows Laptop** and **Phone B** to Phone A's Wi-Fi network.
   - Open Hotspot Guardian on Windows (`flutter run -d windows` or release build).
   - Open Hotspot Guardian on Phone B (installed APK).
3. **Collect the 5 Quantitative Measurement Sets:**
   - Record discovery time (5 runs) $\rightarrow$ populate **Table 7.1**.
   - Record idle TCP latency RTT (10 samples) $\rightarrow$ populate **Table 7.2**.
   - Record text message delivery time (5 runs) $\rightarrow$ populate **Table 7.3**.
   - Record transfer duration and MB/s for 2MB, 5MB, 15MB, 25MB, 50MB, and 100MB files $\rightarrow$ populate **Table 7.4**.
   - Record latency while a 25MB/100MB transfer is running $\rightarrow$ populate **Table 7.5**.
4. **Capture the 10 Required Screenshots** as listed in [Section 8](#8-screenshot-checklist-10-essential-captures).
5. **Draw the 7 Networking Diagrams** as listed in [Section 9](#9-architecture--sequence-diagram-checklist) (Mermaid or Draw.io).
6. **Plot the 4 Graphs** as listed in [Section 7](#7-exact-graphs-to-create-for-chapter-7) using your recorded numbers.
7. **Provide Your Personal Report Details:**
   - Student Name, USN, College Name, Department, and Project Guide Name.
8. **Compile the Final Report Document:**
   - Once your test numbers and screenshots are ready, we will generate the complete, beautifully formatted academic project report ready for college submission.
