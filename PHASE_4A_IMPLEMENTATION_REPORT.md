# Phase 4A — Lightweight Hotspot Network Monitoring Extension
## Implementation Report

**Project:** Hotspot Guardian — Computer Networks Mini-Project  
**Phase:** 4A — Local Hotspot Network Monitoring Dashboard  
**Platform:** Windows (primary), Flutter Desktop  
**Status:** Source files complete. Requires `flutter build windows` / `flutter run -d windows` on the Windows build machine for verification.

---

## 1. Objective

Extend the existing Windows Hotspot Guardian application into a lightweight local
hotspot network monitoring dashboard, **without** replacing or breaking any existing
functionality.

The new monitoring layer adds:

- **Default gateway detection** — IP and MAC address of the phone hotspot gateway.
- **Active client discovery** — devices visible in the Windows ARP/neighbour cache.
- **Observed application traffic** — bytes, messages, uploads, speeds handled exclusively by Hotspot Guardian.
- **Two-tier device view** — Hotspot Guardian protocol peers (can message/send files) vs. ARP-discovered clients (IP/MAC only).

---

## 2. Existing Architecture (Preserved Unchanged)

```
Phone A
   |
   | Mobile Hotspot / Wi-Fi (4G/5G uplink)
   |
Windows Laptop  <- Hotspot Guardian runs here
   |
   +-- HTTPS/TLS server :53317   (Receiver.dart)
   |     +-- /api/localsend/v2/*         (LanLink protocol)
   |     +-- /api/lanlink/v1/*           (LanLink protocol)
   |     +-- /api/hotspot/status         (Web Portal)
   |     +-- /api/hotspot/message        (Web Portal -> text messages)
   |     +-- /api/hotspot/upload         (Web Portal -> file uploads)
   |
   +-- UDP Multicast Discovery           (MulticastDiscovery.dart)
   +-- Subnet TCP Scanner                (SubnetScanner.dart)
   +-- Event Log                         (EventLog singleton)
   +-- Flutter Desktop UI               (home_page.dart)
```

**Storage:** `C:\Users\Welcome\Downloads\LanLink` — unchanged.

All existing routes, file storage, message handling, Open Folder action, and
LanLink/LocalSend discovery continue to work exactly as before.

---

## 3. New Architecture (Phase 4A Additions)

```
AppState (ChangeNotifier)
   |
   +-- refreshNetworkMonitor()     <- new async method (non-blocking)
   |     +-- getDefaultGatewayIp()      (network.dart helper)
   |     |     +-- PowerShell Get-NetRoute   (Windows, primary)
   |     |     +-- route print 0.0.0.0      (Windows, fallback)
   |     |
   |     +-- resolveArpMac(gatewayIp)   (network.dart helper)
   |     |     +-- arp -a <ip>              (Windows ARP cache)
   |     |
   |     +-- ArpScanner.instance.readArpTable()
   |           +-- arp -a                    (full Windows ARP table)
   |
   +-- _gatewayIp         String?
   +-- _gatewayMac        String?
   +-- _activeClients     List<ActiveClient>
   +-- _monitorRefreshing bool

ObservedTraffic (ChangeNotifier singleton)
   +-- totalBytesReceived   -- file upload bytes + message bytes
   +-- totalBytesSent       -- reserved (not yet counted; no fabrication)
   +-- messageCount         -- web portal messages
   +-- uploadCount          -- web portal file uploads
   +-- activeTransfers      -- live transfer count
   +-- lastSpeedBytesPerSec -- most recent completed upload speed
   +-- peakSpeedBytesPerSec -- session peak speed
   +-- lastTransferDuration -- most recent upload duration
```

---

## 4. Gateway Detection

### Method

1. **PowerShell `Get-NetRoute`** (primary, Windows):
```powershell
(Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
 Sort-Object RouteMetric |
 Select-Object -First 1).NextHop
```
Returns the lowest-metric default route — the phone hotspot gateway IP.

2. **`route print 0.0.0.0`** (fallback, Windows):
   Parses the "Active Routes" section for the `0.0.0.0 0.0.0.0 <gateway>` line.

3. **`ip route show default`** (Linux, development only):
   Parses `default via <ip>` for local development / CI use.

### Gateway MAC Resolution

After detecting the gateway IP:
```
arp -a <gatewayIp>
```
The Windows ARP cache always has an entry for the gateway because every routed
packet the laptop sends uses it as the next-hop Layer 2 destination.
The MAC is parsed from the `aa-bb-cc-dd-ee-ff` format and normalised to
lowercase colon-separated form for display.

### Edge Cases

| Situation | Behaviour |
|-----------|-----------|
| PowerShell unavailable | Falls back to `route print` |
| Gateway IP detection fails | `gatewayIp` remains null; UI shows "Detecting..." |
| Gateway MAC not in ARP cache | `gatewayMac` remains null; UI shows "Unavailable" |
| Multiple default routes | Lowest-metric route selected |

---

## 5. ARP / Neighbour Discovery

### Source

`arp -a` on Windows lists all entries the TCP/IP stack has cached:

```
Interface: 10.154.93.130 --- 0x10
  Internet Address      Physical Address      Type
  10.154.93.1           b4-0f-3b-12-34-56    dynamic
  10.154.93.9           a4-77-33-ab-cd-ef    dynamic
  10.154.93.255         ff-ff-ff-ff-ff-ff    static
  224.0.0.22            01-00-5e-00-00-16    static
```

### Filtering

The `ArpScanner` discards:

- Broadcast addresses (`*.255`, `255.255.255.255`)
- Multicast addresses (`224.x`, `225.x`, `239.x`)
- Incomplete entries (`---`)
- Invalid MAC format entries
- Broadcast MAC (`ff:ff:ff:ff:ff:ff`)

`AppState._mergeArpClients()` additionally skips:

- The laptop's own IP addresses
- Known Hotspot Guardian peers (shown in Tier 1 instead)
- The gateway IP (shown in the network info card)

### Important Limitation

> **ARP cache entries do NOT represent all physically connected hotspot devices.**
>
> The Windows ARP cache only contains devices that the laptop has recently
> communicated with. A phone connected to the hotspot but not yet reached by
> any TCP probe or other traffic will not appear in the ARP table.
>
> The existing `SubnetScanner` (TCP port probes) populates ARP entries for
> reachable devices as a side effect. Devices reachable by the subnet scanner
> will appear here after a scan.

---

## 6. Active Client Model

**File:** `lib/core/models/active_client.dart`

```dart
class ActiveClient {
  final String ip;         // IPv4 address (always present)
  final String mac;        // MAC or "Unavailable"
  final String hostname;   // Reverse-DNS / NetBIOS or "Unknown"
  final DateTime firstSeen;
  DateTime lastSeen;
  int? latencyMs;          // null = not yet probed
  bool isOnline;           // true = appeared in most recent ARP scan
}
```

**No fabrication:** MAC is set to `"Unavailable"` and hostname to `"Unknown"` when
the OS has no data. No IP scanning or port probing is performed beyond what
already runs in the existing `SubnetScanner`.

Clients offline for more than 5 minutes are pruned from the list.

---

## 7. Observed Traffic Accounting

**File:** `lib/core/monitoring/observed_traffic.dart`

`ObservedTraffic` is a `ChangeNotifier` singleton wired directly into the
`Receiver`'s web portal handlers.

### Hooks Added to Receiver

| Event | Hook |
|-------|------|
| POST /api/hotspot/message completes successfully | `ObservedTraffic.instance.recordWebMessage(bytes: message.length)` |
| POST /api/hotspot/upload completes successfully | `ObservedTraffic.instance.recordWebUpload(bytes:, speedBytesPerSec:, duration:)` |
| LanLink session file upload completes | `ObservedTraffic.instance.recordLanLinkTransfer(bytes:, speedBytesPerSec:, duration:)` |

The values passed are the **actually measured** values from the existing transfer
logic — no estimates or fabrication.

### What Is NOT Counted

- Traffic between other hotspot clients and the WAN (cellular internet)
- Traffic between clients that does not pass through this laptop
- Sent bytes from HTTP responses (reserved field exists but is not yet populated to avoid inflated numbers)

The UI explicitly displays:

> "Counts ONLY traffic handled by this application.
> Internet usage of other hotspot clients cannot be measured from this laptop."

---

## 8. UI Changes

**File:** `lib/ui/shell/home_page.dart`

### 8.1 Network Information Card (Extended)

Added a second row of info items below the existing Interface / IP / CIDR / Port row:

| Label | Source |
|-------|--------|
| Default Gateway IP | `state.gatewayIp ?? 'Detecting...'` |
| Gateway MAC | `state.gatewayMac?.toUpperCase() ?? 'Unavailable'` |
| Subnet Mask | `state.networkInfo?.subnetMask ?? '255.255.255.0'` |
| Discovered Clients | `state.activeClients.length` (ARP-discovered count) |

### 8.2 Devices Section (Two-Tier)

**Tier 1 — HOTSPOT GUARDIAN DEVICES**

- Shows existing LanLink/Hotspot Guardian peers (unchanged functionality)
- Full message and file-transfer actions available
- Online/offline status with ping latency
- Label: "Running or accessing Hotspot Guardian — full messaging & file transfer available."

**Tier 2 — DISCOVERED HOTSPOT CLIENTS**

- Shows ARP-discovered devices
- IP, MAC (or "Unavailable"), online status, last-seen time
- No action buttons (these are not Hotspot Guardian peers)
- Spinner shown while ARP scan is in flight
- Disclaimer: "Observed via ARP/neighbour table — IP/MAC only. NOT guaranteed to be all hotspot devices."
- When empty: "No additional devices in ARP cache yet. Press Refresh to rescan."

### 8.3 Observed Traffic Card (New)

Appears between the Devices section and Active Transfers section.

Displays 8 stat tiles in two rows:

Row 1: Total Received | Total Sent (Resp.) | Messages | File Uploads

Row 2: Last Speed | Peak Speed | Last Duration | Active Transfers

Amber disclaimer banner:

> "Counts ONLY traffic handled by this application.
> Internet usage of other hotspot clients cannot be measured from this laptop."

**Reset button** clears all counters.

The card uses `ListenableBuilder` on `ObservedTraffic.instance` so it rebuilds
only when traffic events occur, not on every state change.

---

## 9. Security and Accuracy Limitations

| Topic | Decision |
|-------|----------|
| Packet sniffing | NOT implemented. No WinPcap/Npcap. |
| Promiscuous mode | NOT enabled. |
| Internet usage of other clients | NOT claimed. Explicitly disclaimed in UI. |
| Fabricated MAC addresses | Never. "Unavailable" shown when unknown. |
| Fabricated hostnames | Never. "Unknown" shown when unresolved. |
| Fabricated latency | Never. null shown when not probed. |
| ARP completeness | Explicitly noted as partial (only cached entries). |

---

## 10. Why Total Internet Usage Cannot Be Measured From the Laptop

The network topology is:

```
Phone B ────────────┐
Phone C ────────────┤
                    v
          Phone A (Mobile Hotspot / Wi-Fi AP)
                    |
                    | Mobile Data (4G/5G)
                    |
          Internet <- WAN
                    ^
          Phone A (Hotspot Gateway)
                    |
          Laptop (Wi-Fi Client)
                    |
          Hotspot Guardian Application
```

The laptop is a **Wi-Fi Station (STA)** connected to Phone A's hotspot.
It is **not** the access point and **not** a router.

Traffic from Phone B to the Internet travels:
```
Phone B -> Phone A (AP) -> 4G modem -> Internet
```
This unicast traffic is forwarded by Phone A's hotspot NAT/routing — it does
**not** pass through the laptop's Wi-Fi adapter and is therefore completely
invisible to the laptop.

The only traffic the laptop can observe is traffic sent **to** or **by** the laptop itself.
This is exactly what `ObservedTraffic` measures.

---

## 11. Files Created

| File | Purpose |
|------|---------|
| `lib/core/models/active_client.dart` | Model for ARP-discovered devices |
| `lib/core/monitoring/arp_scanner.dart` | Windows ARP cache reader/parser |
| `lib/core/monitoring/gateway_info.dart` | Default gateway IP + MAC detector |
| `lib/core/monitoring/observed_traffic.dart` | Application-level traffic counters |

---

## 12. Files Modified

| File | Changes |
|------|---------|
| `lib/core/util/network.dart` | Added `getDefaultGatewayIp()`, `resolveArpMac()`, helper functions; added `subnetMask` field to `NetworkInterfaceInfo` |
| `lib/state/app_state.dart` | Added Phase 4A imports; added gateway/clients/monitoring fields; added `refreshNetworkMonitor()`, `_mergeArpClients()`, `_compareIps()`; wired initial call in bootstrap and on user-initiated refresh |
| `lib/core/transfer/receiver.dart` | Added `observed_traffic.dart` import; wired `recordWebMessage()` and `recordWebUpload()` calls |
| `lib/ui/shell/home_page.dart` | Added monitoring imports; extended network card with gateway rows; refactored devices section into two tiers; added ARP table, traffic card, and stat tile widgets; updated event log color categories |

---

## 13. Testing Procedure (Windows, Project Owner)

### Prerequisites

- Phone A has mobile data and Wi-Fi hotspot enabled.
- Windows laptop connected to Phone A's hotspot Wi-Fi.
- Flutter Windows development environment ready.

### Step 1 — Build and Run

```powershell
cd C:\path\to\Hotspot-Guardian
flutter pub get
flutter run -d windows
```

### Step 2 — Verify Existing Functionality (Regression Check)

1. App starts -> HTTPS server starts on port 53317.
2. From Phone A's browser: `https://<laptop-ip>:53317/` loads the Web Portal.
3. Send a text message from the browser -> laptop receives and saves it.
4. Upload a file from the browser -> laptop receives and saves it.
5. Event Log shows MESSAGE and TRANSFER entries.
6. "Open Folder" button opens `C:\Users\Welcome\Downloads\LanLink`.

### Step 3 — Verify Phase 4A: Network Info Card

7. In the **NETWORK INFORMATION** card, verify a second row appears:
   - **Default Gateway IP** — should show phone hotspot gateway (e.g. `192.168.43.1`). May take 1–2 seconds to populate.
   - **Gateway MAC** — should resolve within a second (e.g. `A4:77:33:AB:CD:EF`).
   - **Subnet Mask** — should show `255.255.255.0`.
   - **Discovered Clients** — count, may be 0 initially.

### Step 4 — Verify Phase 4A: ARP Client Discovery

8. Click the **Refresh** button to trigger a manual rescan.
9. In the **DEVICES ON HOTSPOT** card, verify:
   - **HOTSPOT GUARDIAN DEVICES** section shows any peers (may be 0 if no other HG device).
   - **DISCOVERED HOTSPOT CLIENTS** shows a table of ARP entries with IP and MAC columns.
   - MACs show as `AA:BB:CC:DD:EE:FF` format or `Unavailable` — never fabricated.

### Step 5 — Verify Phase 4A: Traffic Card

10. Locate the **OBSERVED HOTSPOT GUARDIAN TRAFFIC** card.
11. Verify the amber disclaimer is visible.
12. Send a text message from the Web Portal -> **Messages** counter increments.
13. Upload a file -> **File Uploads** counter increments; **Total Received**, **Last Speed**, **Peak Speed**, **Last Duration** all update.
14. Press **Reset** -> all counters return to zero.

### Step 6 — Event Log

15. Check the Event Log for entries with categories:
    - `NETWORK` — gateway detection and client discovery
    - `DISCOVERY` — new ARP clients found
    - `MESSAGE` — web portal messages
    - `TRANSFER` — file uploads

### Windows CLI Verification Commands

```powershell
# What the gateway detector uses (primary)
(Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object RouteMetric | Select-Object -First 1).NextHop

# What the gateway detector uses (fallback)
route print 0.0.0.0

# What ArpScanner reads
arp -a

# What gateway MAC resolver uses (replace IP with actual gateway)
arp -a 192.168.43.1
```

---

## 14. Expected Screenshots for Final Report

| # | Screenshot | What to show |
|---|-----------|--------------|
| 1 | Full Dashboard | Complete home page with all Phase 4A sections visible |
| 2 | Network Info Card | Gateway IP, Gateway MAC, Subnet Mask, Discovered Clients populated |
| 3 | Two-Tier Devices | Tier 1 (HG peers) and Tier 2 (ARP clients) both visible |
| 4 | Traffic Card — Before | All zeros before any transfer |
| 5 | Traffic Card — After Upload | File upload bytes, speed, duration, upload count populated |
| 6 | Traffic Card — After Message | Message count incremented |
| 7 | ARP Client Table | Table with real IP/MAC entries from `arp -a` output |
| 8 | Event Log | NETWORK, DISCOVERY, MESSAGE, TRANSFER entries |
| 9 | Web Portal | Phone browser showing `https://<ip>:53317/` |
| 10 | PowerShell Verification | Terminal showing `arp -a` and `Get-NetRoute` output |

---

## 15. Physical Implementation Statement

This is a **physical hotspot-network implementation**, not a network simulator.

All measurements are taken from the real Windows TCP/IP stack:

- Gateway detection reads the real Windows routing table.
- ARP entries come from the real Windows Layer 2 cache.
- Transfer speeds are measured from actual byte counts and wall-clock time.
- No mock data, no fabricated devices, no synthetic measurements.

The application runs on a real Windows laptop connected to a real Android mobile
hotspot, and the Web Portal is accessed from a real Android phone browser.

---

## 16. Potential Compile / Syntax Notes for Project Owner

The following points were identified by manual code inspection (`flutter analyze`
was not run — it must be run on the Windows build machine):

1. **`withOpacity` deprecation** — Flutter 3.27+ deprecates `Color.withOpacity()` in favour of `Color.withValues(alpha: ...)`. The existing codebase uses `withOpacity` throughout; Phase 4A follows the same existing style. This does not prevent compilation.

2. **`ActiveClient.mac` mutability** — `ActiveClient.mac` is mutable (`String mac`), allowing `_mergeArpClients` to directly update an entry's MAC address if it was initially `Unavailable` and resolved on a subsequent ARP scan.

3. **`GatewayInfo` class** — `lib/core/monitoring/gateway_info.dart` was created as a standalone utility class. `AppState.refreshNetworkMonitor()` uses the equivalent functions in `network.dart` directly. Both implement the same logic. The `GatewayInfo` class is available for future modular use.

4. **No new `pubspec.yaml` dependencies** — Phase 4A uses only `dart:io`, `dart:async`, `package:flutter/foundation.dart`, and existing project packages.
