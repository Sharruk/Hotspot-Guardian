import 'package:flutter/foundation.dart';

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

  /// Total bytes received by the Hotspot Guardian server (messages + uploads).
  int _totalBytesReceived = 0;
  int get totalBytesReceived => _totalBytesReceived;

  /// Total bytes of responses/confirmations sent by the server.
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

  // ─── Recording ───────────────────────────────────────────────────────────

  /// Called when the Web Portal upload handler completes a file transfer.
  void recordWebUpload({
    required int bytes,
    required double speedBytesPerSec,
    required Duration duration,
  }) {
    _totalBytesReceived += bytes;
    _uploadCount += 1;
    _lastSpeedBytesPerSec = speedBytesPerSec;
    _lastTransferDuration = duration;
    if (speedBytesPerSec > _peakSpeedBytesPerSec) {
      _peakSpeedBytesPerSec = speedBytesPerSec;
    }
    notifyListeners();
  }

  /// Called when the Web Portal message handler receives a text message.
  void recordWebMessage({required int bytes}) {
    _totalBytesReceived += bytes;
    _messageCount += 1;
    notifyListeners();
  }

  /// Called when a LanLink protocol transfer (via Receiver) completes.
  void recordLanLinkTransfer({
    required int bytes,
    required double speedBytesPerSec,
    required Duration duration,
  }) {
    _totalBytesReceived += bytes;
    _uploadCount += 1;
    _lastSpeedBytesPerSec = speedBytesPerSec;
    _lastTransferDuration = duration;
    if (speedBytesPerSec > _peakSpeedBytesPerSec) {
      _peakSpeedBytesPerSec = speedBytesPerSec;
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
    // No listener notification for small response payloads —
    // avoids rebuilding the UI for every tiny JSON response.
  }

  /// Resets all counters (e.g. at app restart or user action).
  void reset() {
    _totalBytesReceived = 0;
    _totalBytesSent = 0;
    _messageCount = 0;
    _uploadCount = 0;
    _activeTransfers = 0;
    _lastSpeedBytesPerSec = 0;
    _peakSpeedBytesPerSec = 0;
    _lastTransferDuration = Duration.zero;
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
