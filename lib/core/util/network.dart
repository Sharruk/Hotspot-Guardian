import 'dart:io';

/// Represents details of an active local network interface.
class NetworkInterfaceInfo {
  const NetworkInterfaceInfo({
    required this.interfaceName,
    required this.ipAddress,
    required this.subnet,
    this.subnetMask = '255.255.255.0',
  });

  final String interfaceName;
  final String ipAddress;

  /// Subnet in CIDR notation, e.g. `10.154.93.0/24`.
  final String subnet;

  /// Dotted-decimal subnet mask, e.g. `255.255.255.0`.
  final String subnetMask;
}

/// Whether [raw] is a canonical IPv4 literal in an RFC 1918 private range.
///
/// Scanned pairing codes are untrusted input. LanLink only advertises
/// non-loopback, non-link-local LAN interfaces, so accepting host names,
/// public addresses, loopback, or link-local targets would only let a QR
/// redirect the app's HTTP client somewhere LanLink itself never advertises.
bool isPrivateLanIPv4(String raw) {
  final address = InternetAddress.tryParse(raw);
  if (address == null || address.type != InternetAddressType.IPv4) {
    return false;
  }
  final octets = address.rawAddress;
  return octets[0] == 10 ||
      (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
      (octets[0] == 192 && octets[1] == 168);
}

/// Returns all non-loopback IPv4 addresses, with the most likely-routable
/// interface first.
///
/// We bind the HTTP server to `0.0.0.0` so it accepts on all of them, but we
/// still use this list to advertise a primary IP in the UI and to pick a
/// sensible broadcast interface for multicast announcements.
Future<List<String>> listLocalIPv4Addresses() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
    includeLinkLocal: false,
  );

  // Rank interfaces so wired/wireless LAN bubbles to the top.
  int rank(NetworkInterface i) {
    final n = i.name.toLowerCase();
    if (n.contains('wlan') || n.contains('wi-fi') || n.contains('wifi')) {
      return 0;
    }
    if (n.contains('eth') || n.contains('en')) return 1;
    if (n.contains('vmware') || n.contains('vbox') || n.contains('docker')) {
      return 10;
    }
    return 5;
  }

  interfaces.sort((a, b) => rank(a).compareTo(rank(b)));

  return [
    for (final iface in interfaces)
      for (final addr in iface.addresses)
        if (!addr.isLoopback) addr.address,
  ];
}

/// Best-guess primary local IP, or `127.0.0.1` if no LAN interface is up.
Future<String> primaryLocalIPv4() async {
  final ips = await listLocalIPv4Addresses();
  return ips.isEmpty ? '127.0.0.1' : ips.first;
}

/// Returns primary network interface info (interface name, IP, and derived /24 subnet).
Future<NetworkInterfaceInfo?> getPrimaryNetworkInfo() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    int rank(NetworkInterface i) {
      final n = i.name.toLowerCase();
      if (n.contains('wlan') || n.contains('wi-fi') || n.contains('wifi')) {
        return 0;
      }
      if (n.contains('eth') || n.contains('en')) return 1;
      if (n.contains('vmware') || n.contains('vbox') || n.contains('docker')) {
        return 10;
      }
      return 5;
    }
    interfaces.sort((a, b) => rank(a).compareTo(rank(b)));
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback && isPrivateLanIPv4(addr.address)) {
          final parts = addr.address.split('.');
          final subnet = parts.length == 4 ? '${parts[0]}.${parts[1]}.${parts[2]}.0/24' : 'N/A';
          return NetworkInterfaceInfo(
            interfaceName: iface.name,
            ipAddress: addr.address,
            subnet: subnet,
          );
        }
      }
    }
    // Fallback to first available interface if no private RFC1918 match
    if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
      final iface = interfaces.first;
      final addr = iface.addresses.first.address;
      final parts = addr.split('.');
      final subnet = parts.length == 4 ? '${parts[0]}.${parts[1]}.${parts[2]}.0/24' : 'N/A';
      return NetworkInterfaceInfo(
        interfaceName: iface.name,
        ipAddress: addr,
        subnet: subnet,
      );
    }
  } catch (_) {}
  return null;
}

/// Attempts to detect the system default gateway IP address.
///
/// On Windows: uses PowerShell `Get-NetRoute` first, then falls back to
/// parsing `route print 0.0.0.0`.
/// On Linux: parses `ip route show default`.
/// Returns null if detection fails; the UI should display `'Detecting...'`.
Future<String?> getDefaultGatewayIp() async {
  try {
    if (Platform.isWindows) {
      // PowerShell: cleanest Windows approach
      final ps = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          '(Get-NetRoute -DestinationPrefix "0.0.0.0/0" | '
              'Sort-Object RouteMetric | Select-Object -First 1).NextHop',
        ],
        runInShell: true,
      );
      if (ps.exitCode == 0) {
        final ip = ps.stdout.toString().trim();
        if (_isValidRoutableIp(ip)) return ip;
      }
      // Fallback: route print
      final r = await Process.run('route', ['print', '0.0.0.0'], runInShell: true);
      if (r.exitCode == 0) {
        return _parseRoutePrint(r.stdout.toString());
      }
    } else if (Platform.isLinux || Platform.isMacOS) {
      final r = await Process.run('ip', ['route', 'show', 'default']);
      if (r.exitCode == 0) {
        final m = RegExp(r'default via (\d+\.\d+\.\d+\.\d+)')
            .firstMatch(r.stdout.toString());
        final ip = m?.group(1);
        if (ip != null && _isValidRoutableIp(ip)) return ip;
      }
    }
  } catch (_) {}
  return null;
}

String? _parseRoutePrint(String output) {
  bool inActive = false;
  for (final line in output.split('\n')) {
    final t = line.trim();
    if (t.contains('Active Routes')) { inActive = true; continue; }
    if (!inActive) continue;
    if (t.startsWith('0.0.0.0')) {
      final parts = t.split(RegExp(r'\s+'));
      if (parts.length >= 3 && _isValidRoutableIp(parts[2])) return parts[2];
    }
  }
  return null;
}

bool _isValidRoutableIp(String ip) {
  if (ip.isEmpty || ip == '0.0.0.0' || ip == '127.0.0.1') return false;
  final parts = ip.split('.');
  if (parts.length != 4) return false;
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n < 0 || n > 255) return false;
  }
  return true;
}

/// Looks up the MAC address for [ip] in the OS ARP cache.
///
/// On Windows: `arp -a <ip>` returns the cached Layer 2 entry.
/// Returns null when no ARP entry exists or detection fails.
Future<String?> resolveArpMac(String ip) async {
  try {
    if (Platform.isWindows) {
      final r = await Process.run('arp', ['-a', ip], runInShell: true);
      if (r.exitCode != 0) return null;
      return _extractMacFromArp(r.stdout.toString(), ip);
    } else if (Platform.isLinux || Platform.isMacOS) {
      final r = await Process.run('arp', [ip]);
      if (r.exitCode != 0) return null;
      final m = RegExp(r'([0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5})')
          .firstMatch(r.stdout.toString());
      return m?.group(1)?.toLowerCase();
    }
  } catch (_) {}
  return null;
}

String? _extractMacFromArp(String output, String targetIp) {
  for (final line in output.split('\n')) {
    final t = line.trim();
    if (!t.startsWith(targetIp)) continue;
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length < 2) continue;
    final mac = parts[1].replaceAll('-', ':').toLowerCase();
    if (RegExp(r'^[0-9a-f]{2}(:[0-9a-f]{2}){5}$').hasMatch(mac)) return mac;
  }
  return null;
}


