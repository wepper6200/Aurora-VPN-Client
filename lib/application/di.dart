import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/clock.dart';
import '../core/device_identity.dart';
import '../core/platform.dart';
import '../data/latency/tcp_latency_tester.dart';
import '../data/mock/in_memory_repositories.dart';
import '../data/mock/mock_vpn_core.dart';
import '../data/storage/database.dart';
import '../data/storage/drift_repositories.dart';
import '../data/storage/field_cipher.dart';
import '../data/subscriptions/subscription_fetcher.dart';
import '../data/vpn/android_apps_source.dart';
import '../data/vpn/android_vpn_controller.dart';
import '../data/vpn/windows_vpn_controller.dart';
import '../domain/servers/repositories.dart';
import '../domain/vpn/vpn_core.dart';
import 'settings/settings_controller.dart';

// Composition root. `main()` overrides the async-initialized providers; tests
// override repositories, network and platform pieces with fakes.

const kUserAgent = 'AuroraVPN/0.1';

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final fieldCipherProvider = Provider<FieldCipher>(
  (ref) => throw UnimplementedError('fieldCipherProvider must be overridden'),
);

final serverRepositoryProvider = Provider<ServerRepository>(
  (ref) => DriftServerRepository(ref.watch(databaseProvider), ref.watch(fieldCipherProvider)),
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => DriftSubscriptionRepository(ref.watch(databaseProvider), ref.watch(fieldCipherProvider)),
);

/// Stable random id of this install + OS/model, for device-limited panels.
final deviceIdentityProvider = FutureProvider<DeviceIdentity>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  const key = 'device.hwid';
  var hwid = prefs.getString(key);
  if (hwid == null) {
    hwid = DeviceIdentity.newHwid();
    await prefs.setString(key, hwid);
  }
  return DeviceIdentity.load(ref.watch(appPlatformProvider), hwid);
});

/// Shared HTTP client (tests replace it with a mock).
final httpClientProvider = Provider<http.Client>((ref) {
  final c = http.Client();
  ref.onDispose(c.close);
  return c;
});

final subscriptionFetcherProvider = Provider<SubscriptionFetcher>((ref) {
  final f = SubscriptionFetcher(
    client: ref.watch(httpClientProvider),
    userAgent: kUserAgent,
    extraHeaders: () async {
      if (!ref.read(settingsProvider).sendHwid) return const {};
      return (await ref.read(deviceIdentityProvider.future)).headers;
    },
  );
  return f;
});

final latencyTesterProvider = Provider<LatencyTester>((ref) => const CompositeLatencyTester());

/// Pings every server the first time the Servers tab opens in a session
/// (tests turn it off to keep timers deterministic).
final autoPingProvider = Provider<bool>((ref) => true);

final installedAppsSourceProvider = Provider<InstalledAppsSource>(
  (ref) => ref.watch(appPlatformProvider).isMobile
      ? const AndroidAppsSource()
      : const StaticInstalledAppsSource([]),
);

/// Incoming deep links (vless://, happ://add/…), including the launch link.
final deepLinksProvider = Provider<Stream<Uri>>((ref) => AppLinks().uriLinkStream);

/// Windows: cores ship in `<app>\core`, runtime files live in LocalAppData.
WindowsVpnController windowsCore({DateTime Function()? now}) => WindowsVpnController(
  coreDir: '${File(Platform.resolvedExecutable).parent.path}\\core',
  runDir: '${Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path}\\AuroraVPN\\run',
  now: now,
);

/// Platform core: libbox (+Xray) on Android, sing-box.exe (+xray.exe) on Windows.
final vpnCoreProvider = Provider<VpnCoreController>((ref) {
  final now = ref.watch(nowProvider);
  final VpnCoreController core = switch (ref.watch(appPlatformProvider)) {
    AppPlatform.android => AndroidVpnController(now: now),
    AppPlatform.windows => windowsCore(now: now),
    AppPlatform.other => MockVpnCoreController(now: now),
  };
  ref.onDispose(core.dispose);
  return core;
});
