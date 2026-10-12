import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';

import '../../domain/logs/log_entry.dart';
import '../../domain/vpn/vpn_core.dart';

/// Simulated core used until the platform controllers land (stages 4–5):
/// realistic state transitions, traffic and log output.
class MockVpnCoreController implements VpnCoreController {
  MockVpnCoreController({
    Map<String, int?> latencies = const {},
    this.connectDelay = const Duration(milliseconds: 1200),
    int seed = 7,
    DateTime Function()? now,
  }) : _now = now ?? clock.now,
       _latencies = Map.unmodifiable(latencies),
       _rnd = Random(seed);

  final DateTime Function() _now;
  final Map<String, int?> _latencies;
  final Duration connectDelay;
  final Random _rnd;

  final _states = StreamController<VpnState>.broadcast();
  final _traffic = StreamController<TrafficSample>.broadcast();
  final _logs = StreamController<LogEntry>.broadcast();

  Timer? _pending;
  Timer? _ticker;
  TrafficSample _last = TrafficSample.zero;

  @override
  Stream<VpnState> get states => _states.stream;

  @override
  Stream<TrafficSample> get traffic => _traffic.stream;

  @override
  Stream<LogEntry> get logs => _logs.stream;

  bool _running = false;

  /// Lets tests and previews inject core log lines.
  void emitLog(LogLevel level, String message) => _log(level, message);

  void _log(LogLevel level, String message) =>
      _logs.add(LogEntry(time: _now(), level: level, message: message));

  @override
  Future<void> start(CoreStartRequest request) async {
    _cancel();
    _running = true;
    _states.add(VpnState(status: VpnStatus.connecting, serverId: request.serverId));
    _log(LogLevel.info, 'sing-box started (mock)');
    _log(LogLevel.debug, 'outbound/proxy[${request.serverId}]: dialing');

    _pending = Timer(connectDelay, () {
      if (!_latencies.containsKey(request.serverId) || _latencies[request.serverId] != null) {
        _states.add(
          VpnState(status: VpnStatus.connected, serverId: request.serverId, connectedAt: _now()),
        );
        _log(LogLevel.info, 'inbound/tun[tun-in]: started at tun0');
        _startTraffic();
      } else {
        _states.add(
          VpnState(
            status: VpnStatus.error,
            serverId: request.serverId,
            error: 'dial tcp: i/o timeout',
          ),
        );
        _running = false;
        _log(LogLevel.error, 'outbound/proxy[${request.serverId}]: dial tcp: i/o timeout');
      }
    });
  }

  void _startTraffic() {
    _last = TrafficSample.zero;
    var phase = 0.0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      phase += 0.45;
      final down = (900000 + 700000 * sin(phase) + _rnd.nextInt(400000)).round().abs();
      final up = (120000 + 80000 * cos(phase * 1.3) + _rnd.nextInt(60000)).round().abs();
      _last = TrafficSample(
        upSpeed: up,
        downSpeed: down,
        upTotal: _last.upTotal + up,
        downTotal: _last.downTotal + down,
      );
      _traffic.add(_last);
      if (_rnd.nextInt(3) == 0) {
        final host = const [
          'api.example.com',
          'cdn.example.net',
          'static.example.org',
        ][_rnd.nextInt(3)];
        _log(LogLevel.info, 'outbound/proxy: outbound connection to $host:443');
      }
    });
  }

  @override
  Future<void> stop() async {
    _cancel();
    _running = false;
    _states.add(const VpnState(status: VpnStatus.disconnecting));
    _log(LogLevel.info, 'sing-box stopped');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _traffic.add(TrafficSample.zero);
    _states.add(const VpnState());
  }

  @override
  Future<bool> isRunning() async => _running;

  @override
  Future<int?> urlTest(String serverId) async {
    final ms = _latencies[serverId];
    await Future<void>.delayed(Duration(milliseconds: 250 + (ms ?? 900) + _rnd.nextInt(250)));
    return ms;
  }

  void _cancel() {
    _pending?.cancel();
    _ticker?.cancel();
  }

  @override
  Future<void> dispose() async {
    _cancel();
    await Future.wait([_states.close(), _traffic.close(), _logs.close()]);
  }
}
