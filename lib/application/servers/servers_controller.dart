import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/parsers/link_serializer.dart';
import '../../domain/servers/server_profile.dart';
import '../../domain/subscriptions/subscription.dart';
import '../di.dart';
import '../settings/settings_controller.dart';
import '../subscriptions/subscription_service.dart';

final serversProvider = StreamProvider<List<ServerProfile>>(
  (ref) => ref.watch(serverRepositoryProvider).watch(),
);

final subscriptionsProvider = StreamProvider<List<Subscription>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).watch(),
);

// ---------------------------------------------------------------------------
// Selection

final selectedServerIdProvider = NotifierProvider<SelectedServerController, String?>(
  SelectedServerController.new,
);

class SelectedServerController extends Notifier<String?> {
  static const _key = 'servers.selected';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_key);

  Future<void> select(String id) async {
    state = id;
    await ref.read(sharedPreferencesProvider).setString(_key, id);
  }
}

/// The selected server, falling back to the first favorite / first server.
final selectedServerProvider = Provider<ServerProfile?>((ref) {
  final servers = ref.watch(serversProvider).value ?? const [];
  if (servers.isEmpty) return null;
  final id = ref.watch(selectedServerIdProvider);
  return servers.where((s) => s.id == id).firstOrNull ??
      servers.where((s) => s.favorite).firstOrNull ??
      servers.first;
});

// ---------------------------------------------------------------------------
// Latency

enum LatencyState { testing, ok, failed }

class LatencyResult {
  const LatencyResult._(this.state, [this.ms]);

  const LatencyResult.testing() : this._(LatencyState.testing);
  const LatencyResult.ok(int ms) : this._(LatencyState.ok, ms);
  const LatencyResult.failed() : this._(LatencyState.failed);

  final LatencyState state;
  final int? ms;
}

final latencyProvider = NotifierProvider<LatencyController, Map<String, LatencyResult>>(
  LatencyController.new,
);

class LatencyController extends Notifier<Map<String, LatencyResult>> {
  static const concurrency = 8;

  @override
  Map<String, LatencyResult> build() => const {};

  bool get isTesting => state.values.any((r) => r.state == LatencyState.testing);

  void _set(String id, LatencyResult r) => state = {...state, id: r};

  /// Tests [servers] in parallel. Servers the tester can't measure (UDP-based
  /// protocols) are skipped and show no result.
  Future<void> test(Iterable<ServerProfile> servers) async {
    final tester = ref.read(latencyTesterProvider);
    final queue = servers.where(tester.supports).toList();
    state = {
      for (final e in state.entries)
        if (!servers.any((s) => s.id == e.key)) e.key: e.value,
      for (final s in queue) s.id: const LatencyResult.testing(),
    };
    final it = queue.iterator;

    Future<void> worker() async {
      while (it.moveNext()) {
        final server = it.current;
        int? ms;
        try {
          ms = await tester.test(server);
        } catch (_) {
          ms = null;
        }
        if (!ref.mounted) return;
        _set(server.id, ms == null ? const LatencyResult.failed() : LatencyResult.ok(ms));
      }
    }

    await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
  }
}

// ---------------------------------------------------------------------------
// Query, sorting and grouping

enum ServerSort { none, latency, name }

class ServerQuery {
  const ServerQuery({this.search = '', this.favoritesOnly = false, this.sort = ServerSort.none});

  final String search;
  final bool favoritesOnly;
  final ServerSort sort;

  ServerQuery copyWith({String? search, bool? favoritesOnly, ServerSort? sort}) => ServerQuery(
    search: search ?? this.search,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    sort: sort ?? this.sort,
  );
}

final serverQueryProvider = NotifierProvider<ServerQueryController, ServerQuery>(
  ServerQueryController.new,
);

class ServerQueryController extends Notifier<ServerQuery> {
  @override
  ServerQuery build() => const ServerQuery();

  void setSearch(String v) => state = state.copyWith(search: v);
  void toggleFavorites() => state = state.copyWith(favoritesOnly: !state.favoritesOnly);
  void setSort(ServerSort v) => state = state.copyWith(sort: v);
}

class ServerGroup {
  const ServerGroup({required this.subscription, required this.servers});

  /// `null` for manually added configs.
  final Subscription? subscription;
  final List<ServerProfile> servers;
}

/// Servers grouped by subscription, filtered and sorted per [serverQueryProvider].
final serverGroupsProvider = Provider<AsyncValue<List<ServerGroup>>>((ref) {
  final serversAsync = ref.watch(serversProvider);
  final subsAsync = ref.watch(subscriptionsProvider);
  final query = ref.watch(serverQueryProvider);
  final latency = ref.watch(latencyProvider);

  if (serversAsync is AsyncError) return AsyncError(serversAsync.error!, serversAsync.stackTrace!);
  final servers = serversAsync.value;
  final subs = subsAsync.value;
  if (servers == null || subs == null) return const AsyncLoading();

  final needle = query.search.trim().toLowerCase();
  bool matches(ServerProfile s) =>
      (!query.favoritesOnly || s.favorite) &&
      (needle.isEmpty ||
          s.name.toLowerCase().contains(needle) ||
          s.host.toLowerCase().contains(needle) ||
          s.protocol.label.toLowerCase().contains(needle));

  int latencyKey(ServerProfile s) {
    final r = latency[s.id];
    return r?.state == LatencyState.ok ? r!.ms! : 1 << 30;
  }

  List<ServerProfile> sorted(Iterable<ServerProfile> list) {
    final l = list.where(matches).toList();
    switch (query.sort) {
      case ServerSort.none:
        break;
      case ServerSort.latency:
        l.sort((a, b) => latencyKey(a).compareTo(latencyKey(b)));
      case ServerSort.name:
        l.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return l;
  }

  final groups = <ServerGroup>[
    for (final sub in subs)
      ServerGroup(
        subscription: sub,
        servers: sorted(servers.where((s) => s.subscriptionId == sub.id)),
      ),
    ServerGroup(
      subscription: null,
      servers: sorted(servers.where((s) => s.subscriptionId == null)),
    ),
  ];
  // Hide empty groups only while filtering, so an empty subscription is still visible.
  final filtering = needle.isNotEmpty || query.favoritesOnly;
  return AsyncData([
    for (final g in groups)
      if (g.servers.isNotEmpty || (!filtering && g.subscription != null)) g,
  ]);
});

/// Actions on servers and subscriptions.
final serverActionsProvider = Provider<ServerActions>(ServerActions.new);

class ServerActions {
  ServerActions(this._ref);

  final Ref _ref;

  Future<void> toggleFavorite(ServerProfile s) =>
      _ref.read(serverRepositoryProvider).upsert(s.copyWith(favorite: !s.favorite));

  Future<void> delete(String id) => _ref.read(serverRepositoryProvider).delete(id);

  Future<void> save(ServerProfile s) => _ref.read(serverRepositoryProvider).upsert(s);

  Future<void> saveSubscription(Subscription s) =>
      _ref.read(subscriptionRepositoryProvider).upsert(s);

  /// Removes the subscription together with its servers.
  Future<void> deleteSubscription(String id) =>
      _ref.read(subscriptionRepositoryProvider).delete(id);

  /// Downloads the subscription again. Throws [SubscriptionFetchException].
  Future<void> refreshSubscription(Subscription s) =>
      _ref.read(subscriptionServiceProvider).refresh(s);

  /// Standard share link for [s] (vless://, ss://…).
  String shareLink(ServerProfile s) => LinkSerializer.toLink(s.name, s.outbound);
}
