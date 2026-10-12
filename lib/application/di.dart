import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
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
import '../domain/servers/repositories.dart';
import '../domain/vpn/vpn_core.dart';

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

final subscriptionFetcherProvider = Provider<SubscriptionFetcher>((ref) {
  final f = SubscriptionFetcher(userAgent: kUserAgent);
  ref.onDispose(f.close);
  return f;
});

final latencyTesterProvider = Provider<LatencyTester>((ref) => const TcpLatencyTester());

final installedAppsSourceProvider = Provider<InstalledAppsSource>(
  (ref) => ref.watch(appPlatformProvider).isMobile
      ? const AndroidAppsSource()
      : const StaticInstalledAppsSource([]),
);

/// Incoming deep links (vless://, happ://add/…), including the launch link.
final deepLinksProvider = Provider<Stream<Uri>>((ref) => AppLinks().uriLinkStream);

/// Platform core: libbox on Android. Windows (stage 5) still uses the mock.
final vpnCoreProvider = Provider<VpnCoreController>((ref) {
  final now = ref.watch(nowProvider);
  final VpnCoreController core = switch (ref.watch(appPlatformProvider)) {
    AppPlatform.android => AndroidVpnController(now: now),
    _ => MockVpnCoreController(now: now),
  };
  ref.onDispose(core.dispose);
  return core;
});
