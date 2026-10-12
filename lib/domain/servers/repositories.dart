import '../routing/routing_settings.dart';
import '../subscriptions/subscription.dart';
import 'server_profile.dart';

abstract interface class ServerRepository {
  /// Emits the full list immediately and after every change.
  Stream<List<ServerProfile>> watch();
  Future<void> upsert(ServerProfile profile);
  Future<void> delete(String id);
}

abstract interface class SubscriptionRepository {
  Stream<List<Subscription>> watch();
  Future<void> upsert(Subscription subscription);
  Future<void> delete(String id);
}

abstract interface class InstalledAppsSource {
  Future<List<InstalledApp>> load({bool includeSystem = false});
}
