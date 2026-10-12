import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/log_mask.dart';
import '../../domain/logs/log_entry.dart';
import '../../domain/vpn/vpn_core.dart';
import 'windows_system_proxy.dart';

/// Windows core: `sing-box.exe` (and `xray.exe` when needed) as child
/// processes next to the app (`<app>/core/`).
///
/// - System-proxy mode: sing-box serves a local mixed inbound; this class
///   sets/clears the WinINet proxy itself (see [SystemProxy]).
/// - TUN mode: wintun via sing-box; needs administrator rights.
/// - Logs come from the cores' stdout/stderr, speeds from the Clash API.
class WindowsVpnController implements VpnCoreController {
  WindowsVpnController({
    required this.coreDir,
    required this.runDir,
    this.systemProxy = const WindowsSystemProxy(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Folder with sing-box.exe, xray.exe, wintun.dll.
  final String coreDir;

  /// Writable folder for configs, cache and the PID file.
  final String runDir;
  final SystemProxy systemProxy;
  final DateTime Function() _now;

  final _states = StreamController<VpnState>.broadcast();
  final _traffic = StreamController<TrafficSample>.broadcast();
  final _logs = StreamController<LogEntry>.broadcast();

  Process? _singbox;
  Process? _xray;
  StreamSubscription<String>? _trafficSub;
  HttpClient? _http;
  String? _serverId;
  String? _proxyAddress;
  String? _lastError;
  bool _stopping = false;
  var _totals = TrafficSample.zero;

  @override
  Stream<VpnState> get states => _states.stream;

  @override
  Stream<TrafficSample> get traffic => _traffic.stream;

  @override
  Stream<LogEntry> get logs => _logs.stream;

  String get _singboxExe => '$coreDir\\sing-box.exe';
  String get _xrayExe => '$coreDir\\xray.exe';
  File get _pidFile => File('$runDir\\core.pids');

  // --- lifecycle --------------------------------------------------------------

  @override
  Future<void> start(CoreStartRequest request) async {
    await stop(silent: true);
    _serverId = request.serverId;
    _stopping = false;
    _lastError = null;
    _totals = TrafficSample.zero;
    _emit(VpnStatus.connecting);

    try {
      if (!File(_singboxExe).existsSync()) throw const _CoreError('core-missing');
      if (request.tun && !await isElevated()) throw const _CoreError('admin-required');
      await Directory(runDir).create(recursive: true);

      if (request.xrayConfigJson != null) {
        if (!File(_xrayExe).existsSync()) throw const _CoreError('core-missing');
        final xrayConfig = File('$runDir\\xray.json')..writeAsStringSync(request.xrayConfigJson!);
        _xray = await Process.start(_xrayExe, [
          'run',
          '-c',
          xrayConfig.path,
        ], workingDirectory: coreDir);
        _pipe(_xray!, _parseXrayLine);
        unawaited(_xray!.exitCode.then((code) => _onExit('xray', code)));
      }

      final config = File('$runDir\\config.json')..writeAsStringSync(request.configJson);
      final started = Completer<void>();
      _singbox = await Process.start(_singboxExe, [
        'run',
        '-c',
        config.path,
        '-D',
        runDir,
        '--disable-color',
      ], workingDirectory: coreDir);
      _pipe(_singbox!, (line) {
        _parseSingboxLine(line);
        if (!started.isCompleted && line.contains('sing-box started')) started.complete();
      });
      unawaited(
        _singbox!.exitCode.then((code) {
          if (!started.isCompleted) started.completeError(_CoreError(_lastError ?? 'exit $code'));
          _onExit('sing-box', code);
        }),
      );
      await _writePids();

      await started.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw const _CoreError('start timeout'),
      );

      final proxyPort = request.systemProxyPort;
      if (proxyPort != null) {
        _proxyAddress = '127.0.0.1:$proxyPort';
        await systemProxy.enable('127.0.0.1', proxyPort);
        await _writePids();
      }
      if (request.clashApiPort != null) {
        _watchTraffic(request.clashApiPort!, request.clashApiSecret);
      }
      _states.add(VpnState(status: VpnStatus.connected, serverId: _serverId, connectedAt: _now()));
    } on _CoreError catch (e) {
      await stop(silent: true);
      _emit(VpnStatus.error, error: e.message);
    } catch (e) {
      await stop(silent: true);
      _emit(VpnStatus.error, error: LogMask.apply('$e'));
    }
  }

  @override
  Future<void> stop({bool silent = false}) async {
    _stopping = true;
    if (!silent) _emit(VpnStatus.disconnecting);
    await _trafficSub?.cancel();
    _trafficSub = null;
    _http?.close(force: true);
    _http = null;
    if (_proxyAddress != null) {
      await systemProxy.disable().catchError((_) {});
      _proxyAddress = null;
    }
    for (final p in [_singbox, _xray]) {
      p?.kill();
    }
    await Future.wait([
      for (final p in [_singbox, _xray])
        if (p != null) p.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => -1),
    ]);
    _singbox = null;
    _xray = null;
    if (_pidFile.existsSync()) _pidFile.deleteSync();
    if (!silent) {
      _traffic.add(TrafficSample.zero);
      _emit(VpnStatus.disconnected);
    }
  }

  void _onExit(String name, int code) {
    if (_stopping) return;
    // The core died on its own: tear everything down and report why.
    _log(LogLevel.error, '$name exited with code $code');
    final reason = _lastError ?? '$name exited ($code)';
    unawaited(stop(silent: true).then((_) => _emit(VpnStatus.error, error: reason)));
  }

  void _emit(VpnStatus status, {String? error}) {
    if (_states.isClosed) return;
    _states.add(VpnState(status: status, serverId: _serverId, error: error));
  }

  // --- recovery after a crash of the app ------------------------------------

  Future<void> _writePids() async {
    final lines = [
      if (_singbox != null) 'pid=${_singbox!.pid}',
      if (_xray != null) 'pid=${_xray!.pid}',
      if (_proxyAddress != null) 'proxy=$_proxyAddress',
    ];
    await _pidFile.writeAsString(lines.join('\n'));
  }

  /// Kills cores and clears the system proxy left over by a previous run that
  /// didn't shut down cleanly (crash, kill from Task Manager).
  Future<void> recover() async {
    if (!_pidFile.existsSync()) return;
    final entries = _pidFile.readAsLinesSync();
    for (final line in entries) {
      final pid = int.tryParse(line.startsWith('pid=') ? line.substring(4) : '');
      if (pid == null) continue;
      final r = await Process.run('tasklist', ['/FI', 'PID eq $pid', '/FO', 'CSV', '/NH']);
      final image = '${r.stdout}'.toLowerCase();
      // Only our own core binaries, never an unrelated process that reused the PID.
      if (image.contains('sing-box.exe') || image.contains('xray.exe')) {
        await Process.run('taskkill', ['/PID', '$pid', '/F']);
      }
    }
    final proxy = entries
        .where((l) => l.startsWith('proxy='))
        .map((l) => l.substring(6))
        .firstOrNull;
    if (proxy != null && await systemProxy.current() == proxy) await systemProxy.disable();
    _pidFile.deleteSync();
  }

  // --- logs ----------------------------------------------------------------------

  void _pipe(Process p, void Function(String line) onLine) {
    for (final stream in [p.stdout, p.stderr]) {
      stream
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen(onLine);
    }
  }

  static final _singboxLevel = RegExp(r'\b(TRACE|DEBUG|INFO|WARN|ERROR|FATAL|PANIC)\b');
  static final _xrayLevel = RegExp(r'\[(Debug|Info|Warning|Error)\]');

  void _parseSingboxLine(String line) {
    final m = _singboxLevel.firstMatch(line);
    final level = switch (m?.group(1)) {
      'TRACE' => LogLevel.trace,
      'DEBUG' => LogLevel.debug,
      'WARN' => LogLevel.warn,
      'ERROR' || 'FATAL' || 'PANIC' => LogLevel.error,
      _ => LogLevel.info,
    };
    final message = m == null ? line : line.substring(m.end).trim();
    if (level == LogLevel.error) _lastError = LogMask.apply(message);
    _log(level, message);
  }

  void _parseXrayLine(String line) {
    final m = _xrayLevel.firstMatch(line);
    final level = switch (m?.group(1)) {
      'Debug' => LogLevel.debug,
      'Warning' => LogLevel.warn,
      'Error' => LogLevel.error,
      _ => LogLevel.info,
    };
    _log(level, 'xray: ${m == null ? line : line.substring(m.end).trim()}');
  }

  void _log(LogLevel level, String message) {
    if (_logs.isClosed || message.trim().isEmpty) return;
    _logs.add(LogEntry(time: _now(), level: level, message: LogMask.apply(message)));
  }

  // --- traffic (Clash API) ---------------------------------------------------------

  void _watchTraffic(int port, String secret) {
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    _http = http;
    Future<void> connect() async {
      try {
        final req = await http.getUrl(Uri.parse('http://127.0.0.1:$port/traffic'));
        if (secret.isNotEmpty) req.headers.set('Authorization', 'Bearer $secret');
        final res = await req.close();
        _trafficSub = res
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .listen(_onTraffic);
      } catch (_) {
        // Stats are best-effort; the tunnel works without them.
      }
    }

    unawaited(connect());
  }

  void _onTraffic(String line) {
    final Object? j;
    try {
      j = jsonDecode(line);
    } on FormatException {
      return;
    }
    if (j is! Map) return;
    final up = (j['up'] as num?)?.toInt() ?? 0;
    final down = (j['down'] as num?)?.toInt() ?? 0;
    // /traffic reports per-second rates; totals are their running sum.
    _totals = TrafficSample(
      upSpeed: up,
      downSpeed: down,
      upTotal: _totals.upTotal + up,
      downTotal: _totals.downTotal + down,
    );
    if (!_traffic.isClosed) _traffic.add(_totals);
  }

  // --- misc -------------------------------------------------------------------------

  /// Administrator check without FFI: `net session` needs elevation.
  static Future<bool> isElevated() async {
    try {
      return (await Process.run('net', ['session'])).exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Orphans of a previous run are killed by [recover] at launch, so only our
  /// own processes count.
  @override
  Future<bool> isRunning() async => _singbox != null;

  @override
  Future<int?> urlTest(String serverId) async => null;

  @override
  Future<void> dispose() async {
    await stop(silent: true);
    await Future.wait([_states.close(), _traffic.close(), _logs.close()]);
  }
}

class _CoreError implements Exception {
  const _CoreError(this.message);

  final String message;
}
