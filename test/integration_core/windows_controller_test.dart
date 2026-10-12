@Tags(['core'])
library;

import 'dart:async';
import 'dart:io';

import 'package:aurora_vpn/data/singbox/config_builder.dart';
import 'package:aurora_vpn/data/vpn/windows_system_proxy.dart';
import 'package:aurora_vpn/data/vpn/windows_vpn_controller.dart';
import 'package:aurora_vpn/domain/routing/routing_settings.dart';
import 'package:aurora_vpn/domain/servers/server_profile.dart';
import 'package:aurora_vpn/domain/settings/app_settings.dart';
import 'package:aurora_vpn/domain/vpn/vpn_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records proxy changes instead of touching the real Windows settings.
class FakeProxy implements SystemProxy {
  String? value;
  final calls = <String>[];

  @override
  Future<void> enable(String host, int port) async {
    value = '$host:$port';
    calls.add('enable $value');
  }

  @override
  Future<void> disable() async {
    calls.add('disable');
    value = null;
  }

  @override
  Future<String?> current() async => value;
}

Future<int> freePort() async {
  final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final p = s.port;
  await s.close();
  return p;
}

void main() {
  final coreDir = Directory('third_party/core/windows').absolute.path;
  final skip = Platform.isWindows && File('$coreDir\\sing-box.exe').existsSync()
      ? false
      : 'sing-box.exe not fetched';
  late Directory runDir;

  setUp(() => runDir = Directory.systemTemp.createTempSync('aurora-run'));
  tearDown(() {
    try {
      runDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<CoreStartRequest> request({bool valid = true}) async {
    final mixed = await freePort();
    final clash = await freePort();
    final config = SingBoxConfigBuilder.buildJson(
      server: const ServerProfile(
        id: 's',
        name: 's',
        outbound: OutboundConfig(
          protocol: ProxyProtocol.trojan,
          host: 'unreachable.example.com',
          port: 443,
          password: 'pw',
          tls: TlsConfig(mode: TlsMode.tls),
        ),
      ),
      routing: const RoutingSettings(mode: RoutingMode.global),
      settings: const AppSettings(),
      options: CoreOptions(
        capture: CaptureMode.systemProxy,
        ruleSetDir: Directory('assets/rules').absolute.path.replaceAll(r'\', '/'),
        mixedPort: mixed,
        clashApiPort: clash,
        clashApiSecret: 'test-secret',
        cachePath: '${runDir.path}/cache.db'.replaceAll(r'\', '/'),
      ),
    );
    return CoreStartRequest(
      serverId: 's',
      configJson: valid ? config : config.replaceFirst('"trojan"', '"no-such-protocol"'),
      tun: false,
      systemProxyPort: mixed,
      clashApiPort: clash,
      clashApiSecret: 'test-secret',
    );
  }

  test(
    'starts sing-box, sets the proxy, streams stats, stops cleanly',
    () async {
      final proxy = FakeProxy();
      final c = WindowsVpnController(coreDir: coreDir, runDir: runDir.path, systemProxy: proxy);
      final states = <VpnStatus>[];
      final sub = c.states.listen((s) => states.add(s.status));
      final logs = <String>[];
      final logSub = c.logs.listen((e) => logs.add(e.message));
      final traffic = c.traffic.first.timeout(const Duration(seconds: 5));

      final req = await request();
      await c.start(req);
      await pumpEventQueue();
      expect(states.last, VpnStatus.connected, reason: 'states: $states\nlogs: ${logs.join('\n')}');
      expect(proxy.value, '127.0.0.1:${req.systemProxyPort}');
      expect(File('${runDir.path}\\core.pids').existsSync(), isTrue);
      expect(logs.any((l) => l.contains('sing-box started')), isTrue);
      await traffic; // the Clash API stream delivers samples

      await c.stop();
      await pumpEventQueue();
      expect(states.last, VpnStatus.disconnected);
      expect(proxy.calls.last, 'disable');
      expect(File('${runDir.path}\\core.pids').existsSync(), isFalse);
      await sub.cancel();
      await logSub.cancel();
      await c.dispose();
    },
    skip: skip,
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'a config the core rejects ends in the error state with its message',
    () async {
      final c = WindowsVpnController(
        coreDir: coreDir,
        runDir: runDir.path,
        systemProxy: FakeProxy(),
      );
      final last = Completer<VpnState>();
      final sub = c.states.listen((s) {
        if (s.status == VpnStatus.error && !last.isCompleted) last.complete(s);
      });
      await c.start(await request(valid: false));
      final s = await last.future.timeout(const Duration(seconds: 20));
      expect(s.error, isNotEmpty);
      await sub.cancel();
      await c.dispose();
    },
    skip: skip,
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'recover() kills an orphaned core and clears our stale proxy',
    () async {
      final proxy = FakeProxy();
      final crashed = WindowsVpnController(
        coreDir: coreDir,
        runDir: runDir.path,
        systemProxy: proxy,
      );
      await crashed.start(await request());
      final pids = File('${runDir.path}\\core.pids').readAsLinesSync();
      final pid = int.parse(pids.firstWhere((l) => l.startsWith('pid=')).substring(4));
      // Simulate an app crash: the controller is gone, the core keeps running.

      final fresh = WindowsVpnController(coreDir: coreDir, runDir: runDir.path, systemProxy: proxy);
      await fresh.recover();
      final alive = await Process.run('tasklist', ['/FI', 'PID eq $pid', '/NH']);
      expect('${alive.stdout}', isNot(contains('sing-box.exe')));
      expect(proxy.value, isNull);
      expect(File('${runDir.path}\\core.pids').existsSync(), isFalse);
    },
    skip: skip,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
