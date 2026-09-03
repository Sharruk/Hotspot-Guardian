/// Represents a device discovered on the local hotspot subnet through
/// ARP / Windows neighbour-table inspection.
///
/// These devices are NOT running Hotspot Guardian — they are simply
/// active IP addresses that the Windows networking stack has cached.
/// They may be phones, tablets, laptops, or IoT devices connected to
/// the same mobile hotspot, but the laptop cannot communicate with them
/// using the LanLink / Hotspot Guardian protocol.
class ActiveClient {
  ActiveClient({
    required this.ip,
    required this.firstSeen,
    this.mac = 'Unavailable',
    this.hostname = 'Unknown',
    this.isOnline = true,
    this.latencyMs,
  }) : lastSeen = firstSeen;

  /// IPv4 address of the discovered device.
  final String ip;

  /// MAC address resolved from the Windows ARP / neighbour table,
  /// or `'Unavailable'` when the OS has no cached entry.
  String mac;

  /// Reverse-DNS / NetBIOS hostname if resolved; `'Unknown'` otherwise.
  final String hostname;

  /// When this device was first seen in the ARP table during this session.
  final DateTime firstSeen;

  /// Most recent time this device was seen in the ARP table.
  DateTime lastSeen;

  /// TCP round-trip latency in milliseconds to the device's first open port,
  /// or null when no probe has succeeded.
  int? latencyMs;

  /// True when the device appeared in the most recent ARP scan.
  bool isOnline;

  /// Human-readable display of the last-seen time relative to now.
  String get lastSeenRelative {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  /// Human-readable MAC, upper-cased for display.
  String get macDisplay {
    if (mac == 'Unavailable' || mac.isEmpty) return 'Unavailable';
    return mac.toUpperCase();
  }

  @override
  String toString() => 'ActiveClient($ip, mac=$mac)';
}
