import 'dart:io';

/// Represents details of an active local network interface.
class NetworkInterfaceInfo {
  const NetworkInterfaceInfo({
    required this.interfaceName,
    required this.ipAddress,
    required this.subnet,
  });

  final String interfaceName;
  final String ipAddress;
  final String subnet;
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

