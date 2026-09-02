# Phase 3A: Physical Test Results — Web Portal over Hotspot

## 1. Test Environment

| Parameter | Configuration / Value |
| :--- | :--- |
| **Phone A** | Mobile Data ON, Mobile Hotspot ON |
| **Laptop OS** | Windows 10/11 |
| **Hotspot SSID Interface** | Wi-Fi |
| **Laptop Local IPv4** | `10.154.93.130` (or dynamic Wi-Fi IP) |
| **Hotspot Subnet** | `10.154.93.0/24` |
| **Hotspot Guardian Port** | `53317` (HTTPS/TLS) |
| **Web Portal URL** | `https://10.154.93.130:53317/` |

---

## 2. Test Execution & Physical Results Checklist

### Test 1: Web Portal Access
- **Action**: Open Chrome on Phone A $\rightarrow$ navigate to `https://10.154.93.130:53317/` $\rightarrow$ proceed through certificate prompt.
- **Expected**: Hotspot Guardian Web Portal UI loads showing Network Status, Message Box, File Upload, and Activity Journal.
- **Status**: `PENDING USER TEST`
- **Observed**: 

### Test 2: Network Status & Ping RTT
- **Action**: Tap **⚡ Ping Server (Measure RTT)** on the phone web page.
- **Expected**: HTTP probe to `/api/hotspot/status` completes and displays real round-trip latency in milliseconds.
- **Status**: `PENDING USER TEST`
- **Measured RTT**: 

### Test 3: Text Message Delivery
- **Action**: In the phone browser, enter `Hello from Phone A` $\rightarrow$ tap **Send Message**.
- **Expected**: Browser displays confirmation alert. Windows app Event Log shows `[MESSAGE]` event. Message `.txt` saved in downloads/storage directory.
- **Status**: `PENDING USER TEST`
- **Saved File Location**: 

### Test 4: File Upload & Throughput
- **Action**: Select a small image/PDF on Phone A $\rightarrow$ tap **🚀 Upload File**.
- **Expected**: Real-time progress bar fills to 100%. Live bytes transferred, duration, and calculated transfer speed ($\text{MB/s}$ / $\text{KB/s}$) are displayed.
- **Status**: `PENDING USER TEST`
- **Uploaded File Name**: 
- **File Size**: 
- **Transfer Duration**: 
- **Transfer Speed**: 

### Test 5: Saved File Verification
- **Action**: Locate and open the uploaded file in the laptop's downloads folder.
- **Expected**: File exists, matches original size, and opens without corruption.
- **Status**: `PENDING USER TEST`

### Test 6: Windows Event Log Verification
- **Action**: Review the live Event Log card on the Windows dashboard.
- **Expected**: Recorded entries for `[SERVER]`, `[NETWORK]`, `[MESSAGE]`, and `[TRANSFER]`.
- **Status**: `PENDING USER TEST`
- **Logged Events**: 

---

## 3. Recommended Screenshots for Project Presentation / Viva
1. **Phone A Browser**: Web Portal UI showing "HOTSPOT GUARDIAN", connected status, and Ping RTT latency.
2. **Phone A Browser Transfer**: File upload progress showing 100% completion, elapsed duration, and speed ($\text{MB/s}$).
3. **Windows Laptop Dashboard**: Hotspot Guardian showing active Wi-Fi IP, Web Portal URL banner, and the Event Log with `[NETWORK]`, `[MESSAGE]`, and `[TRANSFER]` entries.
4. **Laptop File Explorer**: Showing the received message text file and uploaded file in the save folder.
