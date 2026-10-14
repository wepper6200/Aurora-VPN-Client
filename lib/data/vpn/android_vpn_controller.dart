import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/log_mask.dart';
import '../../domain/logs/log_entry.dart';
import '../../domain/vpn/vpn_core.dart';

/// [VpnCoreController] backed by `AuroraVpnService` (VpnService + libbox).
/// Wire format: android/app/src/main/kotlin/.../bridge/VpnChannel.kt.
class AndroidVpnController implements VpnCoreController {
  AndroidVpnController({DateTime Function()? now}) : _now = now ?? DateTime.now {
    _sub = _events.receiveBroadcastStream().listen(_onEvent, onError: (_) {});
  }

  static const _methods = MethodChannel('aurora/vpn');
  static const _events = EventChannel('aurora/vpn/events');

  final DateTime Function() _now;
  late final StreamSubscription<dynamic> _sub;
  final _states = StreamController<VpnState>.broadcast();
  final _traffic = StreamController<TrafficSample>.broadcast();
  final _logs = StreamController<LogEntry>.broadcast();
  String? _serverId;

  @override
  Stream<VpnState> get states => _states.stream;

  @override
  Stream<TrafficSample> get traffic => _traffic.stream;

  @override
  Stream<LogEntry> get logs => _logs.stream;

  void _onEvent(dynamic raw) {
    if (raw is! Map) return;
    final e = raw.cast<String, Object?>();
    switch (e['type']) {
      case 'status':
        final error = e['error'] as String?;
        final status = switch (e['status']) {
          'connecting' => VpnStatus.connecting,
          'connected' => VpnStatus.connected,
          'disconnecting' => VpnStatus.disconnecting,
          _ => error != null ? VpnStatus.error : VpnStatus.disconnected,
        };
        final startedAt = e['startedAt'] as int?;
        _states.add(
          VpnState(
            status: status,
            serverId: _serverId,
            connectedAt: startedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(startedAt),
            error: error == null ? null : LogMask.apply(error),
          ),
        );
        if (status == VpnStatus.disconnected || status == VpnStatus.error) {
          _traffic.add(TrafficSample.zero);
        }
      case 'traffic':
        _traffic.add(
          TrafficSample(
            upSpeed: e['up']! as int,
            downSpeed: e['down']! as int,
            upTotal: e['upTotal']! as int,
            downTotal: e['downTotal']! as int,
          ),
        );
      case 'log':
        _logs.add(
          LogEntry(
            time: _now(),
            level: _level(e['level'] as int? ?? 4),
            message: LogMask.apply(_stripAnsi('${e['message']}')),
          ),
        );
    }
  }

  /// sing-box: 0 panic, 1 fatal, 2 error, 3 warn, 4 info, 5 debug, 6 trace.
  static LogLevel _level(int l) => switch (l) {
    <= 2 => LogLevel.error,
    3 => LogLevel.warn,
    4 => LogLevel.info,
    5 => LogLevel.debug,
    _ => LogLevel.trace,
  };

  static String _stripAnsi(String s) => s.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');

  @override
  Future<void> start(CoreStartRequest request) async {
    _serverId = request.serverId;
    _states.add(VpnState(status: VpnStatus.connecting, serverId: request.serverId));
    final allowed = await _methods.invokeMethod<bool>('prepare') ?? false;
    if (!allowed) {
      _states.add(
        VpnState(status: VpnStatus.error, serverId: request.serverId, error: 'permission-denied'),
      );
      return;
    }
    await _methods.invokeMethod<void>('start', {
      'config': request.configJson,
      'label': request.label,
      'xray': request.xrayConfigJson,
    });
  }

  @override
  Future<void> stop() => _methods.invokeMethod<void>('stop');

  @override
  Future<void> remember(CoreStartRequest request) => _methods.invokeMethod<void>('save', {
    'config': request.configJson,
    'label': request.label,
    'xray': request.xrayConfigJson,
  });

  @override
  Future<bool> isRunning() async {
    final s = await _methods.invokeMapMethod<String, Object?>('state');
    return s?['status'] == 'connecting' || s?['status'] == 'connected';
  }

  /// In-tunnel URL tests arrive with the outbound-group work; TCP ping covers
  /// the disconnected case.
  @override
  Future<int?> urlTest(String serverId) async => null;

  /// Report of the previous crash (JVM exception or Go panic), if any; the
  /// native side deletes it once read.
  static Future<String?> takeLastCrash() async {
    try {
      return await _methods.invokeMethod<String>('lastCrash');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Opens Android's VPN settings (Always-on VPN + block connections without VPN).
  static Future<void> openSystemVpnSettings() => _methods.invokeMethod<void>('openVpnSettings');

  @override
  Future<void> dispose() async {
    await _sub.cancel();
    await Future.wait([_states.close(), _traffic.close(), _logs.close()]);
  }
}
