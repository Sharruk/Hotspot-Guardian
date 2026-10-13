import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-device application traffic accounting record.
///
/// Tracks only traffic handled by Hotspot Guardian to/from a specific device IP.
class DeviceTrafficRecord {
  DeviceTrafficRecord({
    required this.ip,
    this.bytesReceived = 0,
    this.bytesSent = 0,
    this.filesReceivedCount = 0,
    this.filesSentCount = 0,
    this.messageCount = 0,
    DateTime? lastActivity,
  }) : lastActivity = lastActivity ?? DateTime.now();

  final String ip;
  int bytesReceived;
  int bytesSent;
  int filesReceivedCount;
  int filesSentCount;
  int messageCount;
  DateTime lastActivity;

  int get totalBytes => bytesReceived + bytesSent;
  double get totalMB => totalBytes / (1024.0 * 1024.0);
  String get totalMBFormatted => '${totalMB.toStringAsFixed(2)} MB';

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'bytesReceived': bytesReceived,
        'bytesSent': bytesSent,
        'filesReceivedCount': filesReceivedCount,
        'filesSentCount': filesSentCount,
        'messageCount': messageCount,
        'lastActivity': lastActivity.toIso8601String(),
      };

  factory DeviceTrafficRecord.fromJson(Map<String, dynamic> json) =>
      DeviceTrafficRecord(
        ip: json['ip'] as String? ?? '0.0.0.0',
        bytesReceived: json['bytesReceived'] as int? ?? 0,
        bytesSent: json['bytesSent'] as int? ?? 0,
        filesReceivedCount: json['filesReceivedCount'] as int? ?? 0,
        filesSentCount: json['filesSentCount'] as int? ?? 0,
        messageCount: json['messageCount'] as int? ?? 0,
        lastActivity: json['lastActivity'] != null
            ? DateTime.tryParse(json['lastActivity'] as String)
            : null,
      );
}

/// Tracks application-level traffic handled by Hotspot Guardian.
///
/// IMPORTANT: This counter measures ONLY traffic that flows through the
/// Hotspot Guardian server (messages and file uploads from the Web Portal
/// or LanLink protocol). It does NOT and CANNOT measure:
///   - Internet traffic from other hotspot clients to the WAN.
///   - Traffic between other devices and the hotspot gateway.
///   - Any traffic not explicitly processed by this application.
///
/// The laptop is a CLIENT on the mobile hotspot, not the gateway router.
/// Unicast traffic between other clients and the phone gateway is not
/// forwarded to the laptop's Wi-Fi adapter.
class ObservedTraffic extends ChangeNotifier {
  ObservedTraffic._();

  static final ObservedTraffic instance = ObservedTraffic._();
  static const _storageKey = 'hotspot_guardian_device_traffic_v1';

  /// Total bytes received by the Hotspot Guardian server (messages + uploads).
  int _totalBytesReceived = 0;
  int get totalBytesReceived => _totalBytesReceived;

  /// Total bytes sent by Hotspot Guardian (files + messages + responses).
  int _totalBytesSent = 0;
  int get totalBytesSent => _totalBytesSent;

  /// Number of text messages received through the Web Portal.
  int _messageCount = 0;
  int get messageCount => _messageCount;

  /// Number of file uploads received through the Web Portal.
  int _uploadCount = 0;
  int get uploadCount => _uploadCount;

  /// Number of currently active transfers (including LanLink protocol transfers).
  int _activeTransfers = 0;
  int get activeTransfers => _activeTransfers;

  /// Speed of the most recently completed transfer (bytes/second).
  double _lastSpeedBytesPerSec = 0;
  double get lastSpeedBytesPerSec => _lastSpeedBytesPerSec;

  /// Peak speed observed across all transfers (bytes/second).
  double _peakSpeedBytesPerSec = 0;
  double get peakSpeedBytesPerSec => _peakSpeedBytesPerSec;

  /// Duration of the most recently completed transfer.
  Duration _lastTransferDuration = Duration.zero;
  Duration get lastTransferDuration => _lastTransferDuration;

  /// Per-device traffic records keyed by device IPv4 address.
  final Map<String, DeviceTrafficRecord> _perDeviceTraffic = {};
  Map<String, DeviceTrafficRecord> get perDeviceTraffic =>
      Map.unmodifiable(_perDeviceTraffic);

  /// Returns the per-device traffic record for [ip], creating a zeroed record if absent.
  DeviceTrafficRecord getRecordForIp(String ip) {
    return _perDeviceTraffic[ip] ??
        DeviceTrafficRecord(ip: ip, bytesReceived: 0, bytesSent: 0);
  }

  DeviceTrafficRecord _getOrCreate(String ip) {
    return _perDeviceTraffic.putIfAbsent(
      ip,
      () => DeviceTrafficRecord(ip: ip),
    );
  }

  // ─── Persistence ──────────────────────────────────────────────────────────

  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is List) {
          _perDeviceTraffic.clear();
          for (final item in decoded) {
            if (item is Map) {
              final rec = DeviceTrafficRecord.fromJson(
                Map<String, dynamic>.from(item),
              );
              _perDeviceTraffic[rec.ip] = rec;
            }
          }
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _perDeviceTraffic.values.map((r) => r.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(list));
    } catch (_) {}
  }

  // ─── Recording ───────────────────────────────────────────────────────────

  /// Called when the Web Portal upload handler completes a file transfer.
  void recordWebUpload({
    required int bytes,
    required double speedBytesPerSec,
    required Duration duration,
    String clientIp = 'Unknown',
  }) {
    _totalBytesReceived += bytes;
    _uploadCount += 1;
    _lastSpeedBytesPerSec = speedBytesPerSec;
    _lastTransferDuration = duration;
    if (speedBytesPerSec > _peakSpeedBytesPerSec) {
      _peakSpeedBytesPerSec = speedBytesPerSec;
    }
    if (clientIp != 'Unknown' && clientIp.isNotEmpty) {
      final rec = _getOrCreate(clientIp);
      rec.bytesReceived += bytes;
      rec.filesReceivedCount += 1;
      rec.lastActivity = DateTime.now();
      unawaited(_saveToPrefs());
    }
    notifyListeners();
  }

  /// Called when a client visits or interacts with the Web Portal interface.
  void recordWebVisit(String clientIp) {
    if (clientIp != 'Unknown' && clientIp.isNotEmpty && clientIp != 'Client') {
      final rec = _getOrCreate(clientIp);
      rec.lastActivity = DateTime.now();
      unawaited(_saveToPrefs());
      notifyListeners();
    }
  }

  /// Whether [ip] has visited the Web Portal or exchanged traffic.
  bool isWebPortalClient(String ip) {
    return _perDeviceTraffic.containsKey(ip);
  }

  /// Called when the Web Portal message handler receives a text message.
  void recordWebMessage({
    required int bytes,
    String clientIp = 'Unknown',
  }) {
    _totalBytesReceived += bytes;
    _messageCount += 1;
    if (clientIp != 'Unknown' && clientIp.isNotEmpty) {
      final rec = _getOrCreate(clientIp);
      rec.bytesReceived += bytes;
      rec.messageCount += 1;
      rec.lastActivity = DateTime.now();
      unawaited(_saveToPrefs());
    }
    notifyListeners();
  }

  /// Called when a LanLink protocol transfer (via Receiver) completes.
  void recordLanLinkTransfer({
    required int bytes,
    required double speedBytesPerSec,
    required Duration duration,
    String peerIp = 'Unknown',
    bool isMessage = false,
  }) {
    _totalBytesReceived += bytes;
    _uploadCount += 1;
    _lastSpeedBytesPerSec = speedBytesPerSec;
    _lastTransferDuration = duration;
    if (speedBytesPerSec > _peakSpeedBytesPerSec) {
      _peakSpeedBytesPerSec = speedBytesPerSec;
    }
    if (peerIp != 'Unknown' && peerIp.isNotEmpty) {
      final rec = _getOrCreate(peerIp);
      rec.bytesReceived += bytes;
      if (isMessage) {
        rec.messageCount += 1;
      } else {
        rec.filesReceivedCount += 1;
      }
      rec.lastActivity = DateTime.now();
      unawaited(_saveToPrefs());
    }
    notifyListeners();
  }

  /// Records outgoing bytes sent to [peerIp] via Hotspot Guardian.
  void recordOutgoingTransfer({
    required String peerIp,
    required int bytes,
    bool isMessage = false,
  }) {
    _totalBytesSent += bytes;
    if (peerIp != 'Unknown' && peerIp.isNotEmpty) {
      final rec = _getOrCreate(peerIp);
      rec.bytesSent += bytes;
      if (isMessage) {
        rec.messageCount += 1;
      } else {
        rec.filesSentCount += 1;
      }
      rec.lastActivity = DateTime.now();
      unawaited(_saveToPrefs());
    }
    notifyListeners();
  }

  /// Updates the count of currently active transfers.
  void setActiveTransfers(int count) {
    if (_activeTransfers == count) return;
    _activeTransfers = count;
    notifyListeners();
  }

  /// Adds to total bytes sent (response payloads).
  void recordSent(int bytes) {
    _totalBytesSent += bytes;
  }

  /// Resets all counters and wipes persisted per-device traffic.
  Future<void> reset() async {
    _totalBytesReceived = 0;
    _totalBytesSent = 0;
    _messageCount = 0;
    _uploadCount = 0;
    _activeTransfers = 0;
    _lastSpeedBytesPerSec = 0;
    _peakSpeedBytesPerSec = 0;
    _lastTransferDuration = Duration.zero;
    _perDeviceTraffic.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
    notifyListeners();
  }

  // ─── Formatting helpers ───────────────────────────────────────────────────

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '0 B/s';
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  static String formatDuration(Duration d) {
    if (d == Duration.zero) return '--';
    if (d.inSeconds < 1) return '< 1s';
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }
}
