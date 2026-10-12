import 'dart:convert';

import 'package:aurora_vpn/app.dart';
import 'package:aurora_vpn/application/di.dart';
import 'package:aurora_vpn/data/latency/tcp_latency_tester.dart';
import 'package:aurora_vpn/data/mock/demo_data.dart';
import 'package:aurora_vpn/data/mock/in_memory_repositories.dart';
import 'package:aurora_vpn/data/mock/mock_vpn_core.dart';
import 'package:aurora_vpn/data/subscriptions/subscription_fetcher.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aurora_vpn/application/settings/settings_controller.dart';
import 'package:aurora_vpn/core/clock.dart';
import 'package:aurora_vpn/core/platform.dart';
import 'package:aurora_vpn/presentation/features/home/widgets/connect_button.dart';
import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _fontsLoaded = false;

/// Loads every font from the app's FontManifest (Manrope, JetBrains Mono,
/// icon fonts) so goldens show real glyphs instead of Ahem boxes.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

/// Wall-clock origin used by goldens so timestamps render identically.
final goldenEpoch = DateTime(2026, 10, 12, 14, 30);

/// Pumps the full app with mocked preferences and a fixed platform/size.
///
/// Onboarding counts as done unless [prefs] says otherwise. Pass
/// `settle: false` when an endless animation (e.g. the connected halo) is on
/// screen.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  AppPlatform platform = AppPlatform.android,
  Size size = const Size(412, 892),
  Map<String, Object> prefs = const {},
  bool settle = true,
  bool fixedClock = false,
  List<Override> overrides = const [],
  SubscriptionFetcher? fetcher,
}) async {
  SharedPreferences.setMockInitialValues({
    'settings.onboardingDone': true,
    'settings.autoUpdateSubscriptions': false,
    ...prefs,
  });
  PackageInfo.setMockInitialValues(
    appName: 'Aurora VPN',
    packageName: 'dev.aurora.aurora_vpn',
    version: '0.1.0',
    buildNumber: '1',
    buildSignature: '',
  );
  final instance = await SharedPreferences.getInstance();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final start = clock.now();
  DateTime now() => fixedClock ? goldenEpoch.add(clock.now().difference(start)) : clock.now();
  final servers = InMemoryServerRepository(DemoData.servers);
  // The scope owns its container, so unmounting the tree at the end of a test
  // disposes the mock core and cancels its timers.
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(instance),
        appPlatformProvider.overrideWithValue(platform),
        nowProvider.overrideWithValue(now),
        serverRepositoryProvider.overrideWithValue(servers),
        subscriptionRepositoryProvider.overrideWithValue(
          InMemorySubscriptionRepository(DemoData.subscriptions, servers),
        ),
        installedAppsSourceProvider.overrideWithValue(
          const StaticInstalledAppsSource(DemoData.apps),
        ),
        latencyTesterProvider.overrideWithValue(const StaticLatencyTester(DemoData.latencies)),
        deepLinksProvider.overrideWithValue(const Stream<Uri>.empty()),
        subscriptionFetcherProvider.overrideWithValue(
          fetcher ??
              SubscriptionFetcher(
                userAgent: 'test',
                client: MockClient((_) async => http.Response('not found', 404)),
              ),
        ),
        vpnCoreProvider.overrideWith((ref) {
          final core = MockVpnCoreController(latencies: DemoData.latencies, now: now);
          ref.onDispose(core.dispose);
          return core;
        }),
        ...overrides,
      ],
      child: const AuroraApp(),
    ),
  );
  final container = ProviderScope.containerOf(tester.element(find.byType(AuroraApp)));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await pumpFor(tester, const Duration(milliseconds: 800));
  }
  return container;
}

/// Advances fake time in frame-sized steps (for screens that never settle).
Future<void> pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// Taps the connect button and waits until the mock core reports connected.
Future<void> connect(WidgetTester tester, {Duration traffic = const Duration(seconds: 6)}) async {
  await tester.tap(find.byType(ConnectButton));
  await pumpFor(tester, const Duration(milliseconds: 1400));
  await pumpFor(tester, traffic);
}

/// Taps the connect button again and lets the disconnect complete.
Future<void> disconnect(WidgetTester tester) async {
  await tester.tap(find.byType(ConnectButton));
  await pumpFor(tester, const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}
