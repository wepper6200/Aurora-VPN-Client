import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/log_mask.dart';
import '../../domain/logs/log_entry.dart';
import '../di.dart';

class LogsState {
  const LogsState({this.entries = const [], this.paused = false, this.minLevel});

  /// Ring buffer limit.
  static const capacity = 2000;

  final List<LogEntry> entries;
  final bool paused;

  /// `null` shows everything.
  final LogLevel? minLevel;

  List<LogEntry> get visible =>
      minLevel == null ? entries : entries.where((e) => e.level.index >= minLevel!.index).toList();

  LogsState copyWith({List<LogEntry>? entries, bool? paused, LogLevel? Function()? minLevel}) {
    return LogsState(
      entries: entries ?? this.entries,
      paused: paused ?? this.paused,
      minLevel: minLevel != null ? minLevel() : this.minLevel,
    );
  }
}

final logsProvider = NotifierProvider<LogsController, LogsState>(LogsController.new);

class LogsController extends Notifier<LogsState> {
  @override
  LogsState build() {
    final sub = ref.watch(vpnCoreProvider).logs.listen(add);
    ref.onDispose(sub.cancel);
    return const LogsState();
  }

  void add(LogEntry e) {
    if (state.paused) return;
    final next = [...state.entries, e];
    final overflow = next.length - LogsState.capacity;
    state = state.copyWith(entries: overflow > 0 ? next.sublist(overflow) : next);
  }

  /// Adds a multi-line report (e.g. the previous crash) as error entries.
  void addReport(DateTime time, String title, String body) {
    add(LogEntry(time: time, level: LogLevel.error, message: title));
    for (final line in body.split('\n').where((l) => l.trim().isNotEmpty).take(200)) {
      add(LogEntry(time: time, level: LogLevel.error, message: LogMask.apply(line)));
    }
  }

  void togglePause() => state = state.copyWith(paused: !state.paused);
  void setMinLevel(LogLevel? level) => state = state.copyWith(minLevel: () => level);
  void clear() => state = state.copyWith(entries: const []);
}
