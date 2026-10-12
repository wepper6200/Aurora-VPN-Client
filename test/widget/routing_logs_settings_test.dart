import 'package:aurora_vpn/application/logs/logs_controller.dart';
import 'package:aurora_vpn/application/routing/routing_controller.dart';
import 'package:aurora_vpn/application/settings/settings_controller.dart';
import 'package:aurora_vpn/application/servers/servers_controller.dart';
import 'package:aurora_vpn/application/vpn/vpn_controller.dart';
import 'package:aurora_vpn/core/platform.dart';
import 'package:aurora_vpn/data/logs/log_file_target.dart';
import 'package:aurora_vpn/data/mock/demo_data.dart';
import 'package:aurora_vpn/domain/routing/routing_settings.dart';
import 'package:aurora_vpn/domain/vpn/vpn_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  const en = {'settings.language': 'en'};

  group('routing', () {
    testWidgets('mode selection persists and dims presets outside Rules', (tester) async {
      final container = await pumpApp(tester, prefs: en, size: const Size(412, 1200));
      await tester.tap(find.text('Routing'));
      await tester.pumpAndSettle();

      expect(find.text('Presets apply in Rules mode only.'), findsNothing);
      await tester.tap(find.text('Global'));
      await tester.pumpAndSettle();

      expect(container.read(routingProvider).mode, RoutingMode.global);
      expect(find.text('Presets apply in Rules mode only.'), findsOneWidget);
      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString('routing.mode'), 'global');
    });

    testWidgets('android: per-app split tunneling selects apps', (tester) async {
      final container = await pumpApp(tester, prefs: en, size: const Size(412, 1200));
      await tester.tap(find.text('Routing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Per-app routing'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Only selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      final r = container.read(routingProvider);
      expect(r.splitMode, SplitTunnelMode.include);
      expect(r.splitApps, {'org.example.chat'});
    });

    testWidgets('windows: per-app routing is marked Android-only', (tester) async {
      await pumpApp(tester, platform: AppPlatform.windows, size: const Size(460, 1200), prefs: en);
      await tester.tap(find.text('Routing'));
      await tester.pumpAndSettle();
      expect(find.text('Available on Android'), findsOneWidget);
    });
  });

  group('logs', () {
    testWidgets('core logs stream in, filter by level and pause', (tester) async {
      final container = await pumpApp(tester, prefs: en);
      await connect(tester, traffic: const Duration(seconds: 3));
      await tester.tap(find.text('Logs'));
      await pumpFor(tester, const Duration(milliseconds: 600));

      expect(find.textContaining('sing-box started (mock)'), findsOneWidget);
      expect(find.textContaining('dialing'), findsOneWidget);

      await tester.tap(find.text('INFO'));
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(find.textContaining('dialing'), findsNothing);

      await tester.tap(find.byTooltip('Pause'));
      await pumpFor(tester, const Duration(milliseconds: 300));
      final count = container.read(logsProvider).entries.length;
      await pumpFor(tester, const Duration(seconds: 3));
      expect(container.read(logsProvider).entries.length, count);
      expect(find.text('Stream paused'), findsOneWidget);
    });

    testWidgets('export writes every line (filter ignored) and reports the path', (tester) async {
      final target = _MemoryLogTarget();
      final container = await pumpApp(
        tester,
        prefs: en,
        overrides: [logFileTargetProvider.overrideWithValue(target)],
      );
      await connect(tester, traffic: const Duration(seconds: 1));
      await tester.tap(find.text('Logs'));
      await pumpFor(tester, const Duration(milliseconds: 600));
      await tester.tap(find.text('ERROR'));
      await pumpFor(tester, const Duration(milliseconds: 300));

      await tester.tap(find.byTooltip('Export'));
      await pumpFor(tester, const Duration(milliseconds: 300));

      expect(target.name, matches(RegExp(r'^aurora-vpn-logs-\d{8}-\d{6}\.txt$')));
      expect(target.content, contains('# AuroraVPN/'));
      expect(target.content, contains('sing-box started (mock)'));
      final lines = target.content!
          .trim()
          .split('\n')
          .where((l) => !l.startsWith('#') && l.isNotEmpty);
      expect(lines.length, container.read(logsProvider).entries.length);
      expect(find.text('Saved to /downloads/${target.name}'), findsOneWidget);
    });
  });

  group('connection', () {
    testWidgets('connects on launch when enabled', (tester) async {
      final container = await pumpApp(
        tester,
        prefs: {...en, 'settings.autoConnect': true},
        settle: false,
      );
      await pumpFor(tester, const Duration(seconds: 2));
      expect(container.read(vpnStateProvider).status, VpnStatus.connected);
    });

    testWidgets('picking another server while connected switches to it', (tester) async {
      final container = await pumpApp(tester, prefs: en);
      await connect(tester, traffic: const Duration(seconds: 1));
      final servers = container.read(serversProvider).value!;
      final current = container.read(vpnStateProvider).serverId;
      final other = servers.firstWhere((s) => s.id != current && DemoData.latencies[s.id] != null);

      await container.read(selectedServerIdProvider.notifier).select(other.id);
      await pumpFor(tester, const Duration(seconds: 3));

      final s = container.read(vpnStateProvider);
      expect(s.status, VpnStatus.connected);
      expect(s.serverId, other.id);
    });

    testWidgets('stays off by default', (tester) async {
      final container = await pumpApp(tester, prefs: en);
      await pumpFor(tester, const Duration(seconds: 2));
      expect(container.read(vpnStateProvider).status, VpnStatus.disconnected);
    });
  });

  group('settings', () {
    testWidgets('theme and language switch immediately', (tester) async {
      await pumpApp(tester, prefs: en, size: const Size(412, 2400));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(Theme.of(tester.element(find.text('Theme'))).brightness, Brightness.dark);
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.text('Theme'))).brightness, Brightness.light);

      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      expect(find.text('Тема'), findsOneWidget);
    });

    testWidgets('MTU dialog validates the range', (tester) async {
      final container = await pumpApp(tester, prefs: en, size: const Size(412, 2400));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('MTU'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '100');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).mtu, 9000);

      await tester.enterText(find.byType(TextFormField), '1500');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).mtu, 1500);
    });

    testWidgets('platform-specific settings', (tester) async {
      await pumpApp(tester, prefs: en, size: const Size(412, 2400));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Launch at startup'), findsNothing);
      expect(find.text('Tunnel mode'), findsNothing);
    });

    testWidgets('windows shows autostart and tunnel mode', (tester) async {
      await pumpApp(tester, platform: AppPlatform.windows, size: const Size(460, 2400), prefs: en);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Launch at startup'), findsOneWidget);
      expect(find.text('Tunnel mode'), findsOneWidget);
      await tester.tap(find.text('TUN'));
      await tester.pumpAndSettle();
      expect(
        find.text('TUN captures all traffic and requires administrator rights.'),
        findsOneWidget,
      );
    });
  });
}

class _MemoryLogTarget implements LogFileTarget {
  String? name;
  String? content;

  @override
  Future<String?> save(String fileName, String content) async {
    name = fileName;
    this.content = content;
    return '/downloads/$fileName';
  }
}
