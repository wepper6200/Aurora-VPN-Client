import '../routing/routing_settings.dart';
import '../subscriptions/subscription.dart';
import 'server_profile.dart';

abstract interface class ServerRepository {
  /// Emits the full list immediately and after every change.
  Stream<List<ServerProfile>> watch();
  Future<void> upsert(ServerProfile profile);
  Future<void> upsertAll(List<ServerProfile> profiles);
  Future<void> delete(String id);

  /// Atomically replaces every server of [subscriptionId] with [servers].
  Future<void> replaceForSubscription(String subscriptionId, List<ServerProfile> servers);
}

abstract interface class SubscriptionRepository {
  Stream<List<Subscription>> watch();
  Future<void> upsert(Subscription subscription);

  /// Deletes the subscription and all of its servers.
  Future<void> delete(String id);
}

abstract interface class InstalledAppsSource {
  Future<List<InstalledApp>> load({bool includeSystem = false});

  /// PNG icon, or `null` if unavailable.
  Future<List<int>?> icon(String packageName);
}

/// Measures latency to a server without bringing the tunnel up.
abstract interface class LatencyTester {
  bool supports(ServerProfile server);

  /// Milliseconds, or `null` when unreachable.
  Future<int?> test(ServerProfile server);
}
