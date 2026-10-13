import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/models/device.dart';
import '../../core/models/file_info.dart';
import '../../core/models/session.dart';
import '../../core/monitoring/observed_traffic.dart';
import '../../core/platform/incoming_share.dart';
import '../../core/platform/reveal_folder.dart';
import '../../core/util/event_log.dart';
import '../../state/app_state.dart';
import '../v4/v4.dart';
import '../widgets/desktop_drop_region.dart';
import '../widgets/live_session_card.dart';
import 'receive_page.dart';
import 'send_page.dart';
import 'session_display.dart';

/// The Hotspot Guardian Dashboard:
/// - Real-time Network Interface & Subnet Information
/// - Detected Hotspot Devices Table with real latency (ms) & actions
/// - In-flight Transfer Progress & Speed
/// - Live Network Event Journal (DISCOVERY, PING, SERVER, MESSAGE)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    IncomingShare.onShareReceived(_consumePendingShares);
    unawaited(_consumePendingShares());
  }

  Future<void> _consumePendingShares() async {
    final List<FileInfo> shares;
    try {
      shares = await IncomingShare.consume();
    } catch (_) {
      return;
    }
    if (shares.isEmpty || !mounted) return;
    unawaited(Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SendPage(prestagedFiles: shares),
    )));
  }

  @override
  void dispose() {
    IncomingShare.onShareReceived(null);
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _showSendMessageDialog(BuildContext context, Device peer) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text('Message to ${peer.alias}')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target IP: ${peer.ip}:${peer.port}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Type text message to send over local network...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send Message'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (message != null && message.trim().isNotEmpty && mounted) {
      final session = await state.sendTextMessage(peer: peer, message: message);
      if (session != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Message dispatched to ${peer.alias} (${peer.ip})'),
            duration: const Duration(seconds: 2),
          ),
        );
        session.addListener(() {
          if (session.status == TransferStatus.completed) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Message delivered to ${peer.alias}'),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (session.status == TransferStatus.failed) {
            final err = session.files.values.firstOrNull?.error ??
                'Connection timed out or target unreachable';
            messenger.showSnackBar(
              SnackBar(
                content: Text('Failed to deliver message to ${peer.alias}: $err'),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _showSendPortalMessageDialog(
    BuildContext context,
    String? targetIp,
    String displayName,
  ) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.forum_outlined, size: 22, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                targetIp != null
                    ? 'Message to $displayName'
                    : 'Broadcast to Web Portal',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              targetIp != null
                  ? 'Target: $targetIp (Delivered live to Web Portal chat)'
                  : 'Delivered to all active Web Portal clients on the hotspot.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Type text message for the Web Portal live chat...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send to Portal'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (message != null && message.trim().isNotEmpty && mounted) {
      state.sendPortalMessage(text: message.trim(), targetIp: targetIp);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            targetIp != null
                ? 'Message delivered to $displayName ($targetIp) via Web Portal!'
                : 'Message broadcast to all Web Portal clients!',
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final visible = state.visibleSessions;
    final clusters = clusterSessions(visible);
    final hasFinished = visible.any((s) => s.isTerminal);

    final netInfo = state.networkInfo;
    final localIp = netInfo?.ipAddress ??
        (state.localIps.isNotEmpty ? state.localIps.first : '127.0.0.1');
    final interfaceName = netInfo?.interfaceName ?? 'Local Wi-Fi';
    final subnet = netInfo?.subnet ?? '192.168.43.0/24';
    final port = state.port ?? state.settings.port;
    final peers = state.peers.values.toList();

    return DesktopDropRegion(
      onFiles: (files) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SendPage(prestagedFiles: files),
      )),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.security, size: 20, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hotspot Guardian',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Local Hotspot Network Monitor & Communication',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Receive QR / Parameters',
              icon: const Icon(Icons.qr_code),
              onPressed: () => Navigator.of(context).pushNamed(ReceivePage.routeName),
            ),
            IconButton(
              tooltip: 'Transfer History',
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.of(context).pushNamed('/history'),
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (route) => Navigator.of(context).pushNamed(route),
              itemBuilder: (context) => const [
                PopupMenuItem(value: '/help', child: Text('Help & CN Guide')),
                PopupMenuItem(value: '/about', child: Text('About Hotspot Guardian')),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: ListView(
                padding: const EdgeInsets.all(VSpace.x4),
                children: [
                  // 1. NETWORK INFORMATION CARD
                  _buildNetworkInfoCard(
                    context,
                    state: state,
                    scheme: scheme,
                    interfaceName: interfaceName,
                    localIp: localIp,
                    subnet: subnet,
                    port: port,
                    isListening: state.port != null,
                    isScanning: state.isScanning,
                    onRefresh: () => unawaited(state.refreshDiscovery(userInitiated: true)),
                  ),
                  const SizedBox(height: VSpace.x4),

                  // 2. CONNECTED / DETECTED DEVICES (two-tier)
                  _buildDevicesSection(
                    context,
                    state: state,
                    scheme: scheme,
                    peers: peers,
                  ),
                  const SizedBox(height: VSpace.x4),

                  // 3. OBSERVED TRAFFIC CARD
                  _buildTrafficCard(context, scheme: scheme),
                  const SizedBox(height: VSpace.x4),

                  // 4. ACTIVE TRANSFERS (If any)
                  if (clusters.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Active Network Transfers',
                            style: VType.heading.copyWith(color: scheme.onSurface),
                          ),
                        ),
                        if (hasFinished)
                          TextButton(
                            onPressed: state.dismissFinishedSessions,
                            child: const Text('Clear finished'),
                          ),
                      ],
                    ),
                    const SizedBox(height: VSpace.x2),
                    for (final cluster in clusters) ...[
                      _ClusterView(cluster: cluster, state: state),
                      const SizedBox(height: VSpace.x3),
                    ],
                    const SizedBox(height: VSpace.x3),
                  ],

                  // 5. LIVE EVENT & CONNECTION LOG
                  _buildEventLogCard(context, scheme: scheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkInfoCard(
    BuildContext context, {
    required AppState state,
    required ColorScheme scheme,
    required String interfaceName,
    required String localIp,
    required String subnet,
    required int port,
    required bool isListening,
    required bool isScanning,
    required VoidCallback onRefresh,
  }) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.router_outlined, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'NETWORK INFORMATION',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isListening ? Colors.green.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isListening ? Colors.green : Colors.amber,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening ? Colors.green : Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isListening ? 'Connected & Active' : 'Connecting...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isListening ? Colors.green.shade800 : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Rescan Network & Probing',
                  icon: isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 20),
                  onPressed: onRefresh,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    title: 'Interface',
                    value: interfaceName,
                    icon: Icons.wifi,
                    scheme: scheme,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    title: 'Local IPv4',
                    value: localIp,
                    icon: Icons.computer,
                    scheme: scheme,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    title: 'Subnet / CIDR',
                    value: subnet,
                    icon: Icons.hub_outlined,
                    scheme: scheme,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    title: 'Port (TLS/HTTP)',
                    value: port.toString(),
                    icon: Icons.tag,
                    scheme: scheme,
                  ),
                ),
              ],
            ),
            // Gateway rows (Phase 4A)
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    title: 'Default Gateway IP',
                    value: state.gatewayIp ?? 'Detecting...',
                    icon: Icons.router,
                    scheme: scheme,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    title: 'Gateway MAC',
                    value: state.gatewayMac != null
                        ? state.gatewayMac!.toUpperCase()
                        : (state.isMonitorRefreshing ? 'Resolving...' : 'Unavailable'),
                    icon: Icons.memory_outlined,
                    scheme: scheme,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    title: 'Subnet Mask',
                    value: state.networkInfo?.subnetMask ?? '255.255.255.0',
                    icon: Icons.filter_list,
                    scheme: scheme,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    title: 'Discovered Clients',
                    value: state.activeClients.length.toString(),
                    icon: Icons.people_outline,
                    scheme: scheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.public, size: 16, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'WEB PORTAL:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      'https://$localIp:$port/',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: 'https://$localIp:$port/'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Portal URL copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, size: 13, color: scheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Copy URL',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<Directory>(
              future: state.resolveSaveDir(),
              builder: (context, snapshot) {
                final savePath = snapshot.data?.path ?? 'Resolving...';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        'RECEIVED FILES:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          savePath,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () async {
                          final dir = await state.resolveSaveDir();
                          await dir.create(recursive: true);
                          await revealFolder(dir.path);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_open, size: 14, color: scheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Open Folder',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
      ),
    ),
  );
}

  Widget _buildInfoItem({
    required String title,
    required String value,
    required IconData icon,
    required ColorScheme scheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDevicesSection(
    BuildContext context, {
    required AppState state,
    required ColorScheme scheme,
    required List<Device> peers,
  }) {
    final activeClients = state.activeClients;
    final nonPeerClients = activeClients.where((c) => !peers.any((p) => p.ip == c.ip)).toList();
    final isBusy = state.isScanning || state.isMonitorRefreshing;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Section header ───────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.devices, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CONNECTED HOTSPOT DEVICES (${peers.length + nonPeerClients.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () => unawaited(state.refreshDiscovery(userInitiated: true)),
                  icon: isBusy
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 14),
                  label: Text(
                    isBusy ? 'Scanning...' : 'Refresh',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: () => _showSendPortalMessageDialog(context, null, 'All Web Portal Devices'),
                  icon: const Icon(Icons.forum_outlined, size: 14),
                  label: const Text('Portal Chat', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SendPage()),
                  ),
                  icon: const Icon(Icons.link, size: 15),
                  label: const Text('Direct Link', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Limitation explanation banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mobile hotspot gateways do not expose connected-client DHCP lists to Wi-Fi clients. '
                      'Devices below are observed via Windows ARP/neighbour cache and active protocol probes. '
                      'Total WAN/Internet usage is only measurable at the gateway router.',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            if (peers.isEmpty && nonPeerClients.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.wifi_tethering, size: 36, color: scheme.primary),
                    const SizedBox(height: 10),
                    const Text(
                      'Waiting for Hotspot Clients to Connect',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connect phones or other laptops to this Wi-Fi hotspot.\n'
                      'Connected devices do not need to download an app — they can open the Web Portal in any browser:',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        'https://${state.networkInfo?.ipAddress ?? (state.localIps.isNotEmpty ? state.localIps.first : "127.0.0.1")}:${state.port ?? state.settings.port}/',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (peers.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'COMPATIBLE HOTSPOT GUARDIAN RECEIVERS (${peers.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Devices running Hotspot Guardian receiver — messaging and file transfer supported.',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: peers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final peer = peers[index];
                  final latency = state.getLatencyFor(peer.fingerprint);
                  final formattedLatency = latency != null ? '$latency ms' : 'N/A';
                  final mac = state.getMacForIp(peer.ip);
                  final traffic = ObservedTraffic.instance.getRecordForIp(peer.ip);
                  final lastSeen = state.getLastSeenFor(peer.fingerprint);
                  final lastSeenText = lastSeen != null
                      ? _formatRelativeTime(lastSeen)
                      : 'Active';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                peer.deviceType == 'mobile'
                                    ? Icons.phone_android
                                    : Icons.laptop,
                                size: 20,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        peer.alias,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (peer.verified) ...[
                                        const SizedBox(width: 6),
                                        Icon(Icons.verified, size: 16, color: scheme.primary),
                                      ],
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: latency != null
                                              ? Colors.green.withOpacity(0.15)
                                              : Colors.amber.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: latency != null
                                                    ? Colors.green
                                                    : Colors.amber.shade800,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              latency != null ? 'ONLINE' : 'UNREACHABLE',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: latency != null
                                                    ? Colors.green.shade800
                                                    : Colors.amber.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'IPv4: ${peer.ip}:${peer.port}  •  MAC: ${mac.toUpperCase()}  •  ${peer.deviceModel.isNotEmpty ? peer.deviceModel : peer.deviceType}',
                                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            // Latency
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.speed,
                                    size: 14,
                                    color: latency != null && latency < 50
                                        ? Colors.green
                                        : Colors.amber.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedLatency,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 2),
                                  InkWell(
                                    onTap: () => unawaited(state.measurePeerLatency(peer)),
                                    child: const Icon(Icons.refresh, size: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Send Message Action
                            FilledButton.tonalIcon(
                              onPressed: () => _showSendMessageDialog(context, peer),
                              icon: const Icon(Icons.chat_bubble_outline, size: 14),
                              label: const Text('Send Message', style: TextStyle(fontSize: 12)),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Send File Action
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SendPage(targetPeer: peer),
                                ),
                              ),
                              icon: const Icon(Icons.upload_file, size: 14),
                              label: const Text('Send File', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Data usage & Last seen row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.data_usage, size: 14, color: scheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Observed App Data: ${traffic.totalMBFormatted} '
                                  '(${traffic.totalBytes > 0 ? '${ObservedTraffic.formatBytes(traffic.bytesReceived)} Rx / ${ObservedTraffic.formatBytes(traffic.bytesSent)} Tx' : 'No app traffic'})'
                                  '  •  Total WAN: Not measurable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                              Icon(Icons.access_time, size: 13, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                'Last seen: $lastSeenText',
                                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            if (nonPeerClients.isNotEmpty) ...[
              if (peers.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  const Icon(Icons.devices, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'CONNECTED HOTSPOT & WEB PORTAL USERS (${nonPeerClients.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (state.isMonitorRefreshing)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Connected devices on Wi-Fi hotspot — can reside in the Web Portal link without downloading any app.',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: nonPeerClients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final client = nonPeerClients[index];
                  final clientTraffic = ObservedTraffic.instance.getRecordForIp(client.ip);
                  final isWebClient = ObservedTraffic.instance.isWebPortalClient(client.ip);
                  final hasTraffic = clientTraffic.totalBytes > 0;
                  final displayName = client.hostname != 'Unknown'
                      ? client.hostname
                      : 'Device (${client.ip})';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isWebClient
                            ? Colors.blue.withValues(alpha: 0.5)
                            : scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isWebClient ? Icons.language : Icons.devices_other,
                              size: 18,
                              color: isWebClient ? Colors.blue : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isWebClient
                                              ? Colors.blue.withValues(alpha: 0.15)
                                              : (client.isOnline
                                                  ? Colors.teal.withValues(alpha: 0.12)
                                                  : Colors.grey.withValues(alpha: 0.12)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isWebClient
                                              ? 'WEB PORTAL (Active)'
                                              : (client.isOnline ? 'HOTSPOT (ARP)' : 'OFFLINE'),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isWebClient
                                                ? Colors.blue.shade800
                                                : (client.isOnline
                                                    ? Colors.teal.shade800
                                                    : Colors.grey.shade700),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'IPv4: ${client.ip}  •  MAC: ${client.macDisplay}  •  ${isWebClient ? "Active in Web Portal (No app required)" : "Hostname: ${client.hostname}"}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Live Communication Actions
                            FilledButton.tonalIcon(
                              onPressed: () => _showSendPortalMessageDialog(
                                context,
                                client.ip,
                                displayName,
                              ),
                              icon: Icon(
                                isWebClient ? Icons.forum_outlined : Icons.chat_bubble_outline,
                                size: 14,
                              ),
                              label: Text(
                                isWebClient ? 'Portal Chat' : 'Send Message',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Data usage & Last seen row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.data_usage,
                                size: 13,
                                color: isWebClient ? Colors.blue : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  hasTraffic
                                      ? 'Observed Web Portal: ${clientTraffic.totalMBFormatted} (${ObservedTraffic.formatBytes(clientTraffic.bytesReceived)} Rx / ${ObservedTraffic.formatBytes(clientTraffic.bytesSent)} Tx)  •  Total WAN: Not measurable'
                                      : '0.00 MB (Observed App)  •  Total WAN: Not measurable (Gateway managed)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Icon(Icons.access_time, size: 12, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                'Last seen: ${client.lastSeenRelative}',
                                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Phase 4A: Observed Traffic Card ─────────────────────────────────────

  Widget _buildTrafficCard(BuildContext context, {required ColorScheme scheme}) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: ObservedTraffic.instance,
          builder: (context, _) {
            final t = ObservedTraffic.instance;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.monitor_heart_outlined, size: 20, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OBSERVED HOTSPOT GUARDIAN TRAFFIC',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => unawaited(t.reset()),
                      icon: const Icon(Icons.restart_alt, size: 14),
                      label: const Text('Reset', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Scope disclaimer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Counts ONLY traffic handled by this application. '
                          'Internet usage of other hotspot clients cannot be measured from this laptop.',
                          style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Stats grid
                Row(
                  children: [
                    Expanded(
                      child: _buildTrafficStat(
                        icon: Icons.download_outlined,
                        label: 'Total Received',
                        value: ObservedTraffic.formatBytes(t.totalBytesReceived),
                        color: Colors.blue,
                        scheme: scheme,
                      ),
                    ),
                    Expanded(
                      child: _buildTrafficStat(
                        icon: Icons.upload_outlined,
                        label: 'Total Sent',
                        value: ObservedTraffic.formatBytes(t.totalBytesSent),
                        color: Colors.teal,
                        scheme: scheme,
                      ),
                    ),
                    Expanded(
                      child: _buildTrafficStat(
                        icon: Icons.chat_bubble_outline,
                        label: 'Messages',
                        value: t.messageCount.toString(),
                        color: Colors.orange,
                        scheme: scheme,
                      ),
                    ),
                    Expanded(
                      child: _buildTrafficStat(
                        icon: Icons.file_upload_outlined,
                        label: 'File Uploads',
                        value: t.uploadCount.toString(),
                        color: Colors.green,
                        scheme: scheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTrafficStat(
                        icon: Icons.speed,
                        label: 'Last Speed',
                        value: ObservedTraffic.formatSpeed(t.lastSpeedBytesPerSec),
                        color: Colors.purple,
                        scheme: scheme,
                      ),
                    ),
                    Expanded(
                      child: _buildTrafficStat(
                        icon: Icons.trending_up,
                        label: 'Peak Speed',
                        value: ObservedTraffic.formatSpeed(t.peakSpeedBytesPerSec),
                        color: Colors.red,
                        scheme: scheme,
                      ),
                    ),
                    Expanded(
                      child: _buildTrafficStat(
                        icon: Icons.timer_outlined,
                        label: 'Last Duration',
                        value: ObservedTraffic.formatDuration(t.lastTransferDuration),
                        color: Colors.indigo,
                        scheme: scheme,
                      ),
                    ),
                    Expanded(
                      child: _buildTrafficStat(
                        icon: Icons.swap_vert,
                        label: 'Active Transfers',
                        value: t.activeTransfers.toString(),
                        color: Colors.cyan,
                        scheme: scheme,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrafficStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ColorScheme scheme,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ─── End Phase 4A ─────────────────────────────────────────────────────────

  Widget _buildEventLogCard(BuildContext context, {required ColorScheme scheme}) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terminal, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'NETWORK EVENT LOG',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy Log to Clipboard',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () async {
                    final logText = EventLog.instance.export(header: 'Hotspot Guardian Diagnostics Log');
                    await Clipboard.setData(ClipboardData(text: logText));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Event log copied to clipboard'), duration: Duration(seconds: 2)),
                      );
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Clear Log',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => EventLog.instance.clear(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListenableBuilder(
              listenable: EventLog.instance,
              builder: (context, _) {
                final entries = EventLog.instance.entries.reversed.toList();
                if (entries.isEmpty) {
                  return Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Text(
                      'No events logged yet.',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  );
                }
                return Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
                  ),
                  child: ListView.builder(
                    controller: _logScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      final categoryColor = _colorForCategory(entry.category, scheme);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatTime(entry.time),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                entry.category,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.message,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: entry.level == EventLevel.error
                                      ? Colors.red
                                      : entry.level == EventLevel.warn
                                          ? Colors.amber.shade900
                                          : scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForCategory(String category, ColorScheme scheme) {
    switch (category.toUpperCase()) {
      case 'SERVER':
        return Colors.blue;
      case 'DISCOVERY':
        return Colors.teal;
      case 'PING':
        return Colors.purple;
      case 'MESSAGE':
        return Colors.orange;
      case 'NETWORK':
        return Colors.indigo;
      case 'TRANSFER':
        return Colors.green;
      default:
        return scheme.primary;
    }
  }

  String _formatTime(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ClusterView extends StatelessWidget {
  const _ClusterView({required this.cluster, required this.state});

  final SessionCluster cluster;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (cluster.sessions.length == 1) {
      return LiveSessionCard(
        session: cluster.sessions.first,
        state: state,
      );
    }
    final peer = cluster.sessions.first.peer;
    return Container(
      decoration: BoxDecoration(
        borderRadius: VRadius.lgAll,
        border: Border.all(color: scheme.outlineVariant),
        color: scheme.surfaceContainerLow,
      ),
      padding: const EdgeInsets.all(VSpace.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                VSpace.x2, VSpace.x1, VSpace.x2, VSpace.x3),
            child: Text(
              'To ${displayPeerName(state.settings, peer)} · '
              '${cluster.sessions.length} transfers',
              style: VType.label.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          for (final (i, s) in cluster.sessions.indexed) ...[
            if (i > 0) const SizedBox(height: VSpace.x2),
            LiveSessionCard(session: s, state: state),
          ],
        ],
      ),
    );
  }
}
