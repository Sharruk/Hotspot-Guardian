import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/models/active_client.dart';
import '../../core/models/device.dart';
import '../../core/models/file_info.dart';
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
      if (session != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message dispatched to ${peer.alias} (${peer.ip})'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
            Text(
              title,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
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
            // ─── Section header ───────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.devices, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'DEVICES ON HOTSPOT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SendPage()),
                  ),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Direct Link / Radar'),
                ),
              ],
            ),
            const Divider(height: 20),

            // ─── TIER 1: Hotspot Guardian Peers ──────────────────────────
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 15),
                const SizedBox(width: 6),
                Text(
                  'HOTSPOT GUARDIAN DEVICES  (${peers.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Running or accessing Hotspot Guardian — full messaging & file transfer available.',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            if (peers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.wifi_find, size: 32, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    const Text(
                      'No Hotspot Guardian Devices Discovered Yet',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scanning subnet (${state.networkInfo?.subnet ?? "192.168.43.0/24"}) & listening to UDP multicast.\n'
                      'Other devices must be running LanLink / Hotspot Guardian or using the Web Portal.',
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: peers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final peer = peers[index];
                  final latency = state.getLatencyFor(peer.fingerprint);
                  final formattedLatency = latency != null ? '$latency ms' : 'N/A';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            peer.deviceType == 'mobile' ? Icons.phone_android : Icons.laptop,
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                            color: latency != null ? Colors.green : Colors.amber.shade800,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          latency != null ? 'ONLINE' : 'UNREACHABLE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: latency != null ? Colors.green.shade800 : Colors.amber.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'IP: ${peer.ip}:${peer.port}  •  ${peer.deviceModel.isNotEmpty ? peer.deviceModel : peer.deviceType}',
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
                                color: latency != null && latency < 50 ? Colors.green : Colors.amber.shade800,
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
                        // Action Buttons: only for Hotspot Guardian peers
                        OutlinedButton.icon(
                          onPressed: () => _showSendMessageDialog(context, peer),
                          icon: const Icon(Icons.chat_bubble_outline, size: 14),
                          label: const Text('Msg', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                        ),
                        const SizedBox(width: 6),
                        FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SendPage(targetPeer: peer),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file, size: 14),
                          label: const Text('Send File', style: TextStyle(fontSize: 12)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ─── TIER 2: Discovered Hotspot Clients (ARP) ────────────────
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.manage_search, size: 15),
                const SizedBox(width: 6),
                Text(
                  'DISCOVERED HOTSPOT CLIENTS  (${activeClients.length})',
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
              'Observed via ARP/neighbour table — IP/MAC only. NOT guaranteed to be all hotspot devices.',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            if (activeClients.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Text(
                  state.isMonitorRefreshing
                      ? 'Scanning ARP table...'
                      : 'No additional devices in ARP cache yet.\nPress Refresh to rescan.',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              )
            else
              _buildArpClientsTable(context, clients: activeClients, scheme: scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildArpClientsTable(
    BuildContext context, {
    required List<ActiveClient> clients,
    required ColorScheme scheme,
  }) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh.withOpacity(0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          children: [
            _tableHeader('IP ADDRESS', scheme),
            _tableHeader('MAC ADDRESS', scheme),
            _tableHeader('STATUS', scheme),
            _tableHeader('LAST SEEN', scheme),
          ],
        ),
        for (final client in clients)
          TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: scheme.outlineVariant.withOpacity(0.2)),
              ),
            ),
            children: [
              _tableCell(
                child: Row(
                  children: [
                    Icon(Icons.devices_other, size: 13, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      client.ip,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              _tableCell(
                child: Text(
                  client.macDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: client.mac == 'Unavailable'
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
              _tableCell(
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: client.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      client.isOnline ? 'Discovered' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: client.isOnline ? Colors.green.shade800 : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _tableCell(
                child: Text(
                  client.lastSeenRelative,
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _tableHeader(String label, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _tableCell({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: child,
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
                      onPressed: t.reset,
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
                        label: 'Total Sent (Resp.)',
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
