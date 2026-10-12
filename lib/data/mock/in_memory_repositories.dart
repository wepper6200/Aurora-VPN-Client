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

  List<T> get _snapshot => List.unmodifiable(_items.values);

  Stream<List<T>> watch() async* {
    yield _snapshot;
    yield* _changes.stream;
  }

  void put(T v) {
    _items[_key(v)] = v;
    _changes.add(_snapshot);
  }

  void remove(String id) {
    if (_items.remove(id) != null) _changes.add(_snapshot);
  }
}

class InMemoryServerRepository implements ServerRepository {
  InMemoryServerRepository([Iterable<ServerProfile> seed = const []])
    : _store = _Store(seed, (p) => p.id);

  final _Store<ServerProfile> _store;

  @override
  Stream<List<ServerProfile>> watch() => _store.watch();

  @override
  Future<void> upsert(ServerProfile profile) async => _store.put(profile);

  @override
  Future<void> delete(String id) async => _store.remove(id);
}

class InMemorySubscriptionRepository implements SubscriptionRepository {
  InMemorySubscriptionRepository([Iterable<Subscription> seed = const []])
    : _store = _Store(seed, (s) => s.id);

  final _Store<Subscription> _store;

  @override
  Stream<List<Subscription>> watch() => _store.watch();

  @override
  Future<void> upsert(Subscription subscription) async => _store.put(subscription);

  @override
  Future<void> delete(String id) async => _store.remove(id);
}

class StaticInstalledAppsSource implements InstalledAppsSource {
  const StaticInstalledAppsSource(this.apps);

  final List<InstalledApp> apps;

  @override
  Future<List<InstalledApp>> load({bool includeSystem = false}) async =>
      includeSystem ? apps : apps.where((a) => !a.isSystem).toList();
}
