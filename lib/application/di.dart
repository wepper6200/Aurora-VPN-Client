import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../data/latency/tcp_latency_tester.dart';
import '../data/mock/in_memory_repositories.dart';
import '../data/mock/mock_vpn_core.dart';
import '../data/storage/database.dart';
import '../data/storage/drift_repositories.dart';
import '../data/storage/field_cipher.dart';
import '../data/subscriptions/subscription_fetcher.dart';
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

/// Android package list arrives with the native bridge (stage 6).
final installedAppsSourceProvider = Provider<InstalledAppsSource>(
  (ref) => const StaticInstalledAppsSource([]),
);

/// Incoming deep links (vless://, happ://add/…), including the launch link.
final deepLinksProvider = Provider<Stream<Uri>>((ref) => AppLinks().uriLinkStream);

/// Simulated core until the platform controllers land (stages 4–5).
final vpnCoreProvider = Provider<VpnCoreController>((ref) {
  final core = MockVpnCoreController(now: ref.watch(nowProvider));
  ref.onDispose(core.dispose);
  return core;
});
