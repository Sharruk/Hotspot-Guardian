# Hotspot Guardian — Architecture Diagram Source Definitions

This document contains the text and Mermaid specification definitions for all 7 technical engineering diagrams used in the **Hotspot Guardian** technical report.

---

## Diagram 1: Overall Physical & Logical Hotspot Network Architecture

```mermaid
graph TD
    subgraph Mobile Hotspot Gateway
        AP["Phone SoftAP (10.66.85.199)<br/>DHCP Server & Wi-Fi Gateway"]
    end

    subgraph Host Laptop Engine
        Host["Windows Guardian Host (10.66.85.129)<br/>Flutter App + Shelf Server (:53317)"]
        subgraph Internal Services
            Disc["Layer 2/3 Discovery<br/>• Windows ARP Cache (/arp -a)<br/>• Subnet Sweep 10.66.85.0/24<br/>• UDP Multicast 224.0.0.167"]
            Shelf["Embedded Shelf Services<br/>• HTTPS/TLS X.509 Endpoint<br/>• Streamed IOSink File Pipe<br/>• In-Memory Two-Way Chat Hub<br/>• ObservedTraffic Accounting"]
        end
    end

    subgraph Mobile Browser Clients
        ClientA["Mobile Browser Client (Zero-Install)<br/>• Accesses https://10.66.85.129:53317/<br/>• Real-time RTT Latency Probe<br/>• Live Chat Feed (2.5s Polling)<br/>• Zero-Memory File Upload Stream"]
    end

    AP -- "802.11 Wi-Fi WLAN" --> Host
    AP -- "802.11 Wi-Fi WLAN" --> ClientA
    Host <--> |"HTTPS / TLS (Port 53317)"| ClientA
```

---

## Diagram 2: Web Portal Request Flow & Route Execution

```mermaid
sequenceDiagram
    autonumber
    actor Client as Mobile Browser Client
    participant Router as Shelf HTTP Router (:53317)
    participant State as AppState & Traffic Engine
    participant Disk as Local Storage (LanLink)

    Client->>Router: GET / or GET /index.html
    Router-->>Client: 200 OK (Embedded SPA HTML5/CSS3/JS)
    
    Client->>Router: GET /api/hotspot/status (RTT Probe)
    Router-->>Client: 200 OK { alias, port: 53317, timestamp }

    Client->>Router: GET /api/hotspot/messages (Poll 2.5s)
    Router-->>Client: 200 OK [ { sender, text, timestamp } ]

    Client->>Router: POST /api/hotspot/message { text: "Hello" }
    Router->>State: Ingest message & notify listeners
    Router-->>Client: 200 OK { success: true }

    Client->>Router: POST /api/hotspot/upload?filename=doc.pdf
    Router->>Disk: Stream chunked bytes directly to IOSink
    Router->>State: Record bytes received to ObservedTraffic
    Router-->>Client: 200 OK { success: true, speed: "2.4 MB/s" }
```

---

## Diagram 3: Streaming File Upload Sequence (Zero-Memory Pipeline)

```mermaid
sequenceDiagram
    autonumber
    actor Browser as Browser Client
    participant Shelf as Shelf Server (:53317)
    participant Disk as Host Filesystem (Downloads/LanLink)

    Browser->>Shelf: POST /api/hotspot/upload?filename=sample.txt
    Note over Shelf: Open non-blocking IOSink on disk
    loop Chunked Stream Transfer
        Browser->>Shelf: Binary Stream Chunk (64 KB)
        Shelf->>Disk: sink.add(chunk) & sink.flush()
    end
    Browser->>Shelf: End-Of-Stream (EOF)
    Shelf->>Disk: sink.close()
    Shelf-->>Browser: 200 OK { success: true, speed: "...", duration: "..." }
```

---

## Diagram 4: Two-Way Live Chatroom & Messaging Transport

```mermaid
sequenceDiagram
    autonumber
    actor Phone as Mobile Browser
    participant HostServer as Shelf Server (:53317)
    actor Laptop as Host Laptop UI

    Phone->>HostServer: POST /api/hotspot/message { text: "Hello from phone" }
    HostServer->>Laptop: EventLog.add() & Update Chat Feed UI
    HostServer-->>Phone: 200 OK

    Laptop->>HostServer: broadcastPortalMessage("Acknowledged from laptop")
    HostServer->>HostServer: Store in _portalMessages buffer

    loop Active Polling (Every 2.5s)
        Phone->>HostServer: GET /api/hotspot/messages
        HostServer-->>Phone: 200 OK (New laptop message rendered)
    end
```

---

## Diagram 5: Hybrid Device Discovery Workflow

```mermaid
flowchart TD
    Start([Initiate Discovery Scan]) --> ARP[Query Windows Neighbor Cache: arp -a]
    ARP --> Parse[Parse IPv4, Physical MAC & Interface Type]
    Parse --> Classify[Classify: Subnet Devices vs Receivers]
    Classify --> Probe[Parallel TCP Port Sweep: 10.66.85.1-254 on Port 53317]
    Probe --> Resp{Port 53317 Open?}
    Resp -- Yes --> Recv[Mark as Compatible Receiver: Hotspot Guardian Node]
    Resp -- No --> SubnetOnly[Mark as Observed Subnet Leaf Node]
    Recv --> UI[Update Connected Hotspot Devices Dashboard]
    SubnetOnly --> UI
```

---

## Diagram 6: Observed Application Data Accounting Architecture

```mermaid
graph LR
    subgraph Inbound Traffic Rx
        Rx1[Web Portal File Uploads]
        Rx2[Incoming Chat Messages]
        Rx3[LocalSend P2P Payloads]
    end

    subgraph ObservedTraffic Singleton
        Engine[ObservedTraffic Engine<br/>• Cumulative Rx/Tx Bytes<br/>• Upload/Message Counters<br/>• Peak & Instantaneous Speeds<br/>• Session Resets]
    end

    subgraph Outbound Traffic Tx
        Tx1[Host Chat Broadcasts]
        Tx2[P2P Manifest Payloads]
    end

    Rx1 --> Engine
    Rx2 --> Engine
    Rx3 --> Engine
    Engine --> Tx1
    Engine --> Tx2
```

---

## Diagram 7: End-to-End User Operational Workflow

```mermaid
flowchart LR
    A[1. Enable Phone Hotspot] --> B[2. Connect Laptop to Wi-Fi]
    B --> C[3. Launch Hotspot Guardian]
    C --> D[4. Open Web Portal URL on Phone]
    D --> E[5. Test RTT Latency Probe]
    E --> F[6. Send Real-Time Chat Message]
    F --> G[7. Stream File to Host Disk]
    G --> H[8. Verify Disk & Event Logs]
```
