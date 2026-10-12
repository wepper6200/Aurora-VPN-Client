import 'dart:async';

import '../../domain/routing/routing_settings.dart';
import '../../domain/servers/repositories.dart';
import '../../domain/servers/server_profile.dart';
import '../../domain/subscriptions/subscription.dart';

/// Keyed list that replays its current value to every new listener.
class _Store<T> {
  _Store(Iterable<T> seed, this._key) {
    for (final v in seed) {
      _items[_key(v)] = v;
    }
  }

  final String Function(T) _key;
  final _items = <String, T>{};
  final _changes = StreamController<List<T>>.broadcast();

  List<T> get snapshot => List.unmodifiable(_items.values);

  Stream<List<T>> watch() async* {
    yield snapshot;
    yield* _changes.stream;
  }

  void putAll(Iterable<T> values) {
    for (final v in values) {
      _items[_key(v)] = v;
    }
    _changes.add(snapshot);
  }

  void removeWhere(bool Function(T) test) {
    _items.removeWhere((_, v) => test(v));
    _changes.add(snapshot);
  }
}

/// Test / preview double for [ServerRepository].
class InMemoryServerRepository implements ServerRepository {
  InMemoryServerRepository([Iterable<ServerProfile> seed = const []])
    : _store = _Store(seed, (p) => p.id);

  final _Store<ServerProfile> _store;

  List<ServerProfile> get snapshot => _store.snapshot;

  @override
  Stream<List<ServerProfile>> watch() =>
      _store.watch().map((l) => [...l]..sort((a, b) => a.sortIndex.compareTo(b.sortIndex)));

  @override
  Future<void> upsert(ServerProfile profile) async => _store.putAll([profile]);

  @override
  Future<void> upsertAll(List<ServerProfile> profiles) async => _store.putAll(profiles);

  @override
  Future<void> delete(String id) async => _store.removeWhere((p) => p.id == id);

  @override
  Future<void> replaceForSubscription(String subscriptionId, List<ServerProfile> servers) async {
    _store
      ..removeWhere((p) => p.subscriptionId == subscriptionId)
      ..putAll(servers);
  }

  /// Mirrors the database's ON DELETE CASCADE.
  void deleteForSubscription(String subscriptionId) =>
      _store.removeWhere((p) => p.subscriptionId == subscriptionId);
}

class InMemorySubscriptionRepository implements SubscriptionRepository {
  InMemorySubscriptionRepository([Iterable<Subscription> seed = const [], this.servers])
    : _store = _Store(seed, (s) => s.id);

  final _Store<Subscription> _store;

  /// When set, deleting a subscription also deletes its servers.
  final InMemoryServerRepository? servers;

  @override
  Stream<List<Subscription>> watch() => _store.watch();

  @override
  Future<void> upsert(Subscription subscription) async => _store.putAll([subscription]);

  @override
  Future<void> delete(String id) async {
    _store.removeWhere((s) => s.id == id);
    servers?.deleteForSubscription(id);
  }
}

class StaticInstalledAppsSource implements InstalledAppsSource {
  const StaticInstalledAppsSource(this.apps);

  final List<InstalledApp> apps;

  @override
  Future<List<InstalledApp>> load({bool includeSystem = false}) async =>
      includeSystem ? apps : apps.where((a) => !a.isSystem).toList();
}
