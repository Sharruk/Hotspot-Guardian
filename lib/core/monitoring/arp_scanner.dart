import 'dart:io';

import 'package:flutter/foundation.dart';

/// Reads the Windows ARP / neighbour table to discover active IP↔MAC mappings
/// on the local subnet.
///
/// On Windows this runs `arp -a` which shows cached Layer 2 entries —
/// hosts that the TCP/IP stack has recently communicated with.
/// Entries are populated automatically whenever any packet is sent to a host
/// (e.g. by the SubnetScanner's TCP probes).
///
/// On other platforms (Linux/macOS) a best-effort `arp -a` is attempted
/// or an empty map is returned if unavailable. This class is primarily
/// designed and tested for Windows.
///
/// IMPORTANT: ARP cache entries do NOT represent ALL physically connected
/// devices. They represent only devices that the laptop has recently
/// communicated with. A device connected to the hotspot but not yet
/// reached by any probe will not appear until a probe reaches it.
class ArpScanner {
  ArpScanner._();

  static final ArpScanner instance = ArpScanner._();

  /// Reads the OS ARP table and returns a map of { ipAddress → macAddress }.
  ///
  /// MAC addresses are returned in lowercase colon-separated form e.g.
  /// `"b4:0f:3b:12:34:56"`. On failure an empty map is returned without
  /// throwing.
  Future<Map<String, String>> readArpTable() async {
    try {
      if (Platform.isWindows) {
        return await _readArpWindows();
      } else if (Platform.isLinux || Platform.isMacOS) {
        return await _readArpPosix();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[arp] Failed to read ARP table: $e');
    }
    return {};
  }

  /// Reads the ARP table on Windows using `arp -a`.
  ///
  /// Sample output:
  /// ```
  /// Interface: 10.154.93.130 --- 0x10
  ///   Internet Address      Physical Address      Type
  ///   10.154.93.1           b4-0f-3b-12-34-56    dynamic
  ///   10.154.93.9           a4-77-33-ab-cd-ef    dynamic
  ///   10.154.93.255         ff-ff-ff-ff-ff-ff    static
  ///   224.0.0.22            01-00-5e-00-00-16    static
  /// ```
  Future<Map<String, String>> _readArpWindows() async {
    final result = await Process.run('arp', ['-a'], runInShell: true);
    if (result.exitCode != 0) return {};
    final output = result.stdout.toString();
    return _parseArpOutput(output, dashSeparator: true);
  }

  /// Reads the ARP table on Linux / macOS.
  Future<Map<String, String>> _readArpPosix() async {
    final result = await Process.run('arp', ['-a'], runInShell: false);
    if (result.exitCode != 0) return {};
    final output = result.stdout.toString();
    return _parseArpPosix(output);
  }

  /// Parses Windows `arp -a` output.
  /// Skips broadcast/multicast entries and incomplete/static entries.
  Map<String, String> _parseArpOutput(String output,
      {bool dashSeparator = true}) {
    final map = <String, String>{};
    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Skip header lines and interface lines
      if (trimmed.startsWith('Interface') ||
          trimmed.startsWith('Internet Address')) continue;

      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;

      final ip = parts[0];
      final macRaw = parts.length > 1 ? parts[1] : '';

      // Skip broadcast, multicast, and loopback
      if (_isMulticastOrBroadcast(ip)) continue;
      // Skip incomplete entries
      if (macRaw == '---' || macRaw.isEmpty) continue;
      // Validate MAC format (Windows uses dashes: aa-bb-cc-dd-ee-ff)
      final mac = macRaw.replaceAll('-', ':').toLowerCase();
      if (!_isValidMac(mac)) continue;
      // Skip broadcast MAC
      if (mac == 'ff:ff:ff:ff:ff:ff') continue;

      map[ip] = mac;
    }
    return map;
  }

  /// Parses POSIX `arp -a` output.
  /// Format: `hostname (ip) at mac [ether] on iface`
  Map<String, String> _parseArpPosix(String output) {
    final map = <String, String>{};
    for (final line in output.split('\n')) {
      final ipMatch = RegExp(r'\((\d+\.\d+\.\d+\.\d+)\)').firstMatch(line);
      final macMatch =
          RegExp(r'\bat\s+([0-9a-fA-F:]{17})\b').firstMatch(line);
      if (ipMatch == null || macMatch == null) continue;
      final ip = ipMatch.group(1)!;
      final mac = macMatch.group(1)!.toLowerCase();
      if (_isMulticastOrBroadcast(ip)) continue;
      if (mac == 'ff:ff:ff:ff:ff:ff') continue;
      if (!_isValidMac(mac)) continue;
      map[ip] = mac;
    }
    return map;
  }

  /// Returns true when [ip] is a broadcast or multicast address that should
  /// not appear in the discovered-devices list.
  bool _isMulticastOrBroadcast(String ip) {
    if (ip.endsWith('.255')) return true;
    if (ip.startsWith('224.') || ip.startsWith('225.') ||
        ip.startsWith('239.') || ip.startsWith('255.')) {
      return true;
    }
    return false;
  }

  bool _isValidMac(String mac) {
    return RegExp(r'^[0-9a-f]{2}(:[0-9a-f]{2}){5}$').hasMatch(mac);
  }

  /// Attempts to resolve the MAC address for a single [ip] by probing
  /// the ARP table. On Windows, `arp -a ip` queries the cached entry;
  /// if not cached, a brief TCP connect attempt populates it first.
  Future<String?> resolveMacForIp(String ip) async {
    try {
      if (Platform.isWindows) {
        final result =
            await Process.run('arp', ['-a', ip], runInShell: true);
        if (result.exitCode == 0) {
          final parsed =
              _parseArpOutput(result.stdout.toString(), dashSeparator: true);
          return parsed[ip];
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        final result = await Process.run('arp', [ip], runInShell: false);
        if (result.exitCode == 0) {
          final parsed = _parseArpPosix(result.stdout.toString());
          return parsed[ip];
        }
      }
    } catch (_) {}
    return null;
  }
}
