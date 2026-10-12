import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../domain/logs/log_entry.dart';
import '../../domain/vpn/vpn_core.dart';
import '../di.dart';
import 'vpn_controller.dart';

enum ConnectionIssue {
  /// The proxy server's own host name doesn't resolve (stale subscription
  /// entry, typo, blocked DNS).
  serverNotFound,

  /// Connections through the proxy keep failing.
  serverUnreachable,
}

/// Flags a tunnel that is "connected" but can't actually carry traffic, by
/// watching the core's error log. Cleared on reconnect and after a quiet
/// period.
final connectionIssueProvider = NotifierProvider<ConnectionHealth, ConnectionIssue?>(
  ConnectionHealth.new,
);

class ConnectionHealth extends Notifier<ConnectionIssue?> {
  static const window = Duration(seconds: 15);
  static const threshold = 5;

  final _failures = <DateTime>[];
  Timer? _quiet;

  @override
  ConnectionIssue? build() {
    final sub = ref.watch(vpnCoreProvider).logs.listen(_onLog);
    ref.listen(vpnStateProvider.select((s) => s.status), (_, status) {
      if (status != VpnStatus.connected) _reset();
    });
    ref.onDispose(() {
      sub.cancel();
      _quiet?.cancel();
    });
    return null;
  }

  void _reset() {
    _failures.clear();
    _quiet?.cancel();
    if (state != null) state = null;
  }

  void _onLog(LogEntry e) {
    if (e.level != LogLevel.error) return;
    final m = e.message;
    // sing-box: "connection: open connection to X using outbound/vless[proxy]: <reason>"
    if (!m.contains('open connection') || !m.contains('[proxy]')) return;

    final now = ref.read(nowProvider)();
    if (m.contains('NXDOMAIN') || m.contains('no such host')) {
      state = ConnectionIssue.serverNotFound;
    } else {
      _failures
        ..add(now)
        ..removeWhere((t) => now.difference(t) > window);
      if (_failures.length >= threshold && state == null) state = ConnectionIssue.serverUnreachable;
    }
    // Forget the issue once errors stop for a while.
    _quiet?.cancel();
    _quiet = Timer(const Duration(seconds: 30), () {
      _failures.clear();
      if (ref.mounted) state = null;
    });
  }
}
