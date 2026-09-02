# Hotspot Guardian — File Storage Location

## 1. Upload Flow

```
Phone Browser (Chrome / Safari)
    │
    │  HTTPS POST /api/hotspot/upload (Port 53317)
    ▼
Laptop: Hotspot Guardian Shelf Server
    │
    │  Receiver.dart (_handleWebUpload)
    ▼
Storage Directory Resolver (AppState.resolveSaveDir)
    │
    │  Safe Path Sanitization (splitSafeRelativePath & uniqueOutputPath)
    ▼
Received File Stored on Local Disk
```

---

## 2. Actual Storage Location

Determined directly from the source code implementation ([`lib/state/app_state.dart:L700-L730`](file:///d:/Visual_Studio_Code/College_Assignments/sem_5/Computer_Networks/Mini_Project/lanlink/lib/state/app_state.dart#L700-L730)):

```
Windows Storage Directory:
C:\Users\Welcome\Downloads\LanLink
```

### Exact Path Breakdown:
1. `getDownloadsDirectory()` resolves standard user profile downloads directory: `C:\Users\Welcome\Downloads`.
2. The application appends the subdirectory `\LanLink`.
3. All browser text messages (e.g. `Message 2026-09-02 21.07.57.txt`) and uploaded files (images, PDFs, documents) are directly saved inside this folder.

---

## 3. How to Find Received Files on Windows

### Method A: From the Hotspot Guardian Dashboard (One-Click)
1. In the **Hotspot Guardian** Windows application, look at the **Network Information** card.
2. Under **RECEIVED FILES**, click **Open Folder**.
3. Windows File Explorer will immediately open the folder `C:\Users\Welcome\Downloads\LanLink`.

### Method B: From Windows File Explorer
1. Press `Win + E` to open File Explorer.
2. Navigate to **Downloads** $\rightarrow$ **LanLink**.
3. Path: `C:\Users\Welcome\Downloads\LanLink`.

### Method C: From PowerShell / Command Prompt
```powershell
explorer.exe "$env:USERPROFILE\Downloads\LanLink"
```

---

## 4. How to Verify a Received File

1. **Verify Existence**: Check that the file uploaded from Phone A is listed in `C:\Users\Welcome\Downloads\LanLink`.
2. **Verify Filename**: The filename is safely sanitized (traversal characters stripped) and preserves the original extension.
3. **Verify File Size**: Right-click the file $\rightarrow$ **Properties** $\rightarrow$ verify the byte size matches the declared size shown during upload on the phone browser.
4. **Verify File Integrity**: Double-click the file to open it with the default Windows application (Photos, Acrobat, Notepad, etc.) to ensure it opens without corruption.

---

## 5. Current Physical Test Evidence

The following physical test results have been verified over the real mobile hotspot:

| Test Item | Verification Status | Observed Evidence |
| :--- | :--- | :--- |
| **Portal Access** | ✅ **Verified** | Phone A opened `https://10.154.93.130:53317/` |
| **Ping / RTT** | ✅ **Verified** | Active probe to `/api/hotspot/status` succeeded |
| **Message Transfer** | ✅ **Verified** | Message saved: `Message 2026-09-02 21.07.57.txt` (18 bytes) |
| **File Upload (Image)** | ✅ **Verified** | Photo uploaded: `Screenshot_...jpg` (562,034 bytes) |
| **File Upload (PDF)** | ✅ **Verified** | PDF uploaded: `Simulated_Annealing_Assignment_...pdf` (385,601 bytes) |
| **Transfer Speed** | ✅ **Verified** | Real throughput dynamically measured and displayed |
| **Transfer Duration** | ✅ **Verified** | Live elapsed transfer time calculated and logged |
