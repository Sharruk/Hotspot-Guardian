import 'dart:io';

import 'package:flutter/foundation.dart';

/// Detects the system's default IPv4 gateway and its MAC address.
///
/// On Windows, parses `route print 0.0.0.0` to find the active default route.
/// The gateway's MAC is resolved by reading the Windows ARP cache
/// (`arp -a <gatewayIp>`), which is always populated because every Internet
/// and LAN packet the laptop sends passes through the gateway.
///
/// On Linux, parses `ip route show default` as a fallback for development.
///
/// Returns null for any field that cannot be determined; the UI should
/// display `'Detecting...'` or `'Unavailable'` in those cases.
class GatewayInfo {
  GatewayInfo._();

  static final GatewayInfo instance = GatewayInfo._();

  /// Detects the default gateway IP address for the primary active interface.
  ///
  /// Returns the gateway IPv4 address as a String, or null on failure.
  Future<String?> detectGatewayIp() async {
    try {
      if (Platform.isWindows) {
        return await _detectGatewayWindows();
      } else if (Platform.isLinux || Platform.isMacOS) {
        return await _detectGatewayPosix();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[gateway] Detection failed: $e');
    }
    return null;
  }

  /// Resolves the MAC address of the gateway from the ARP cache.
  ///
  /// On Windows: `arp -a <gatewayIp>` returns the cached Layer 2 address.
  /// The ARP entry is always present because the gateway is the next-hop for
  /// all routed traffic; the Windows TCP/IP stack resolves it at startup.
  Future<String?> resolveGatewayMac(String gatewayIp) async {
    try {
      if (Platform.isWindows) {
        return await _resolveArpWindows(gatewayIp);
      } else if (Platform.isLinux || Platform.isMacOS) {
        return await _resolveArpPosix(gatewayIp);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[gateway] MAC resolution failed: $e');
    }
    return null;
  }

  // ─── Windows implementation ───────────────────────────────────────────────

  /// Parses `route print 0.0.0.0` on Windows.
  ///
  /// The active routes section contains lines like:
  /// ```
  ///          0.0.0.0          0.0.0.0   10.154.93.9  10.154.93.130     35
  /// ```
  /// Column order: Network Destination, Netmask, Gateway, Interface, Metric
  Future<String?> _detectGatewayWindows() async {
    // Try PowerShell first — more reliable and parses cleanly
    final psResult = await Process.run(
      'powershell',
      [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        '(Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object RouteMetric | Select-Object -First 1).NextHop',
      ],
      runInShell: true,
    );
    if (psResult.exitCode == 0) {
      final ip = psResult.stdout.toString().trim();
      if (_isValidGatewayIp(ip)) return ip;
    }

    // Fallback: parse classic `route print`
    final result = await Process.run(
      'route',
      ['print', '0.0.0.0'],
      runInShell: true,
    );
    if (result.exitCode != 0) return null;

    return _parseRoutePrint(result.stdout.toString());
  }

  String? _parseRoutePrint(String output) {
    // Find the "IPv4 Route Table" section and look for the 0.0.0.0 default
    bool inActive = false;
    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.contains('Active Routes')) {
        inActive = true;
        continue;
      }
      if (!inActive) continue;
      // Stop at next section
      if (trimmed.startsWith('=') && !trimmed.contains('0.0.0.0')) break;

      // Match lines where Network Destination and Netmask are both 0.0.0.0
      if (trimmed.startsWith('0.0.0.0')) {
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final gateway = parts[2];
          if (_isValidGatewayIp(gateway)) return gateway;
        }
      }
    }
    return null;
  }

  Future<String?> _resolveArpWindows(String ip) async {
    final result = await Process.run('arp', ['-a', ip], runInShell: true);
    if (result.exitCode != 0) return null;
    return _extractMacFromArpOutput(result.stdout.toString(), ip);
  }

  // ─── POSIX (Linux / macOS) implementation — dev fallback ─────────────────

  Future<String?> _detectGatewayPosix() async {
    final result =
        await Process.run('ip', ['route', 'show', 'default'], runInShell: false);
    if (result.exitCode != 0) return null;
    // Output: "default via 192.168.1.1 dev wlan0 ..."
    final match =
        RegExp(r'default via (\d+\.\d+\.\d+\.\d+)').firstMatch(result.stdout.toString());
    return match?.group(1);
  }

  Future<String?> _resolveArpPosix(String ip) async {
    final result = await Process.run('arp', [ip], runInShell: false);
    if (result.exitCode != 0) return null;
    final macMatch =
        RegExp(r'([0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5})').firstMatch(result.stdout.toString());
    return macMatch?.group(1)?.toLowerCase();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String? _extractMacFromArpOutput(String output, String targetIp) {
    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.startsWith(targetIp)) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final mac = parts[1].replaceAll('-', ':').toLowerCase();
      if (RegExp(r'^[0-9a-f]{2}(:[0-9a-f]{2}){5}$').hasMatch(mac)) {
        return mac;
      }
    }
    return null;
  }

  bool _isValidGatewayIp(String ip) {
    // Must be a valid IPv4, not loopback, not 0.0.0.0
    if (ip.isEmpty || ip == '0.0.0.0' || ip == '127.0.0.1') return false;
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }
}
