import 'package:flutter/foundation.dart';

/// A lightweight in-memory ring buffer of recent network and system events,
/// used to power the live Hotspot Guardian Event Log.
class EventLog extends ChangeNotifier {
  EventLog._();

  static final EventLog instance = EventLog._();

  static const int maxEntries = 200;

  final List<EventLogEntry> _entries = <EventLogEntry>[];

  List<EventLogEntry> get entries => List.unmodifiable(_entries);

  /// Append an event line. Oldest entries roll off once [maxEntries] is reached.
  void add(
    String message, {
    EventLevel level = EventLevel.info,
    String category = 'SYSTEM',
  }) {
    final entry = EventLogEntry(
      time: DateTime.now(),
      level: level,
      category: category,
      message: message,
    );
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    if (kDebugMode) {
      debugPrint('[$category:${level.name}] $message');
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// Render the buffer as a single clipboard-friendly string, oldest first.
  String export({String? header}) {
    final buffer = StringBuffer();
    if (header != null && header.isNotEmpty) {
      buffer.writeln(header);
      buffer.writeln('-' * 32);
    }
    for (final e in _entries) {
      buffer.writeln(e.format());
    }
    return buffer.toString().trimRight();
  }
}

enum EventLevel { info, warn, error }

class EventLogEntry {
  EventLogEntry({
    required this.time,
    required this.level,
    required this.message,
    this.category = 'SYSTEM',
  });

  final DateTime time;
  final EventLevel level;
  final String category;
  final String message;

  String format() {
    final two = (int n) => n.toString().padLeft(2, '0');
    final t = '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
    return '$t  ${category.padRight(11)}  ${level.name.toUpperCase().padRight(5)}  $message';
  }
}

