import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lanlink/core/monitoring/observed_traffic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ObservedTraffic.instance.reset();
  });

  group('DeviceTrafficRecord', () {
    test('initializes with zeros and calculates MB', () {
      final record = DeviceTrafficRecord(
        ip: '192.168.43.50',
        lastActivity: DateTime.now(),
      );

      expect(record.totalBytes, 0);
      expect(record.totalMB, 0.0);
      expect(record.totalMBFormatted, '0.00 MB');
    });

    test('serializes and deserializes correctly', () {
      final now = DateTime.now();
      final record = DeviceTrafficRecord(
        ip: '192.168.43.50',
        bytesReceived: 1048576, // 1 MB
        bytesSent: 524288,     // 0.5 MB
        filesReceivedCount: 2,
        filesSentCount: 1,
        messageCount: 3,
        lastActivity: now,
      );

      final jsonMap = record.toJson();
      final restored = DeviceTrafficRecord.fromJson(jsonMap);

      expect(restored.ip, '192.168.43.50');
      expect(restored.bytesReceived, 1048576);
      expect(restored.bytesSent, 524288);
      expect(restored.filesReceivedCount, 2);
      expect(restored.filesSentCount, 1);
      expect(restored.messageCount, 3);
      expect(restored.totalBytes, 1572864);
      expect(restored.totalMBFormatted, '1.50 MB');
    });
  });

  group('ObservedTraffic Service', () {
    test('records web uploads and messages', () async {
      final traffic = ObservedTraffic.instance;
      await traffic.loadFromPrefs();

      traffic.recordWebUpload(
        bytes: 2097152, // 2 MB
        speedBytesPerSec: 1048576,
        duration: const Duration(seconds: 2),
        clientIp: '192.168.43.75',
      );
      traffic.recordWebMessage(
        bytes: 120,
        clientIp: '192.168.43.75',
      );

      final record = traffic.getRecordForIp('192.168.43.75');
      expect(record.bytesReceived, 2097152 + 120);
      expect(record.filesReceivedCount, 1);
      expect(record.messageCount, 1);
      expect(record.totalMBFormatted, '2.00 MB');
    });

    test('records outgoing LanLink file transfers and messages', () async {
      final traffic = ObservedTraffic.instance;
      await traffic.loadFromPrefs();

      traffic.recordOutgoingTransfer(
        peerIp: '192.168.43.100',
        bytes: 3145728, // 3 MB
        isMessage: false,
      );
      traffic.recordOutgoingTransfer(
        peerIp: '192.168.43.100',
        bytes: 64,
        isMessage: true,
      );

      final record = traffic.getRecordForIp('192.168.43.100');
      expect(record.bytesSent, 3145728 + 64);
      expect(record.filesSentCount, 1);
      expect(record.messageCount, 1);
    });

    test('persists to and restores from SharedPreferences', () async {
      final traffic = ObservedTraffic.instance;
      traffic.recordWebUpload(
        bytes: 1048576,
        speedBytesPerSec: 1048576,
        duration: const Duration(seconds: 1),
        clientIp: '192.168.43.200',
      );

      // Verify written to mock prefs
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('hotspot_guardian_device_traffic_v1');
      expect(storedJson, isNotNull);
      final decoded = jsonDecode(storedJson!) as List;
      expect(decoded.any((item) => (item as Map)['ip'] == '192.168.43.200'), isTrue);

      // Reset in memory and reload
      await traffic.reset();
      // Write back manually to test deserialization from prefs
      await prefs.setString('hotspot_guardian_device_traffic_v1', storedJson);
      expect(traffic.perDeviceTraffic.containsKey('192.168.43.200'), isFalse);

      await traffic.loadFromPrefs();
      expect(traffic.perDeviceTraffic.containsKey('192.168.43.200'), isTrue);
      expect(traffic.getRecordForIp('192.168.43.200').bytesReceived, 1048576);
    });

    test('reset clears all in-memory and persistent records', () async {
      final traffic = ObservedTraffic.instance;
      traffic.recordWebUpload(
        bytes: 5000,
        speedBytesPerSec: 5000,
        duration: const Duration(seconds: 1),
        clientIp: '192.168.43.201',
      );
      expect(traffic.perDeviceTraffic.containsKey('192.168.43.201'), isTrue);

      await traffic.reset();
      expect(traffic.perDeviceTraffic, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('hotspot_guardian_device_traffic_v1'), isFalse);
    });
  });
}
