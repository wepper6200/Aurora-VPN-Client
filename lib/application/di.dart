import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../data/mock/demo_data.dart';
import '../data/mock/in_memory_repositories.dart';
import '../data/mock/mock_vpn_core.dart';
import '../domain/servers/repositories.dart';
import '../domain/vpn/vpn_core.dart';

// Composition root. Stage 2 wires in-memory/mock implementations; later
// stages swap them for drift repositories and the platform cores.

final serverRepositoryProvider = Provider<ServerRepository>(
  (ref) => InMemoryServerRepository(DemoData.servers),
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => InMemorySubscriptionRepository(DemoData.subscriptions),
);

final installedAppsSourceProvider = Provider<InstalledAppsSource>(
  (ref) => const StaticInstalledAppsSource(DemoData.apps),
);

final vpnCoreProvider = Provider<VpnCoreController>((ref) {
  final core = MockVpnCoreController(latencies: DemoData.latencies, now: ref.watch(nowProvider));
  ref.onDispose(core.dispose);
  return core;
});
