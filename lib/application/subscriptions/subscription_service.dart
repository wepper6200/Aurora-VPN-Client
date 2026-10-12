import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ids.dart';
import '../../data/parsers/import_item.dart';
import '../../data/subscriptions/subscription_fetcher.dart';
import '../../domain/servers/server_profile.dart';
import '../../domain/subscriptions/subscription.dart';
import '../di.dart';
import '../servers/servers_controller.dart';
import '../settings/settings_controller.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>(SubscriptionService.new);

class SubscriptionService {
  SubscriptionService(this._ref);

  final Ref _ref;

  /// Fetches [url] and stores the subscription with its servers.
  Future<Subscription> add({
    required String url,
    String? name,
    Duration? updateInterval,
    bool autoUpdate = true,
  }) async {
    final fetched = await _ref.read(subscriptionFetcherProvider).fetch(url);
    final meta = fetched.meta;
    final sub = Subscription(
      id: newId(),
      name: (name?.trim().isNotEmpty ?? false) ? name!.trim() : meta.title ?? Uri.parse(url).host,
      url: url,
      updatedAt: clock.now(),
      updateInterval: updateInterval ?? meta.updateInterval ?? const Duration(hours: 12),
      autoUpdate: autoUpdate,
      usage: meta.usage,
      supportUrl: meta.supportUrl,
    );
    await _ref.read(subscriptionRepositoryProvider).upsert(sub);
    await _ref
        .read(serverRepositoryProvider)
        .replaceForSubscription(
          sub.id,
          _merge(sub.id, fetched.outcome.servers, existing: const []),
        );
    return sub;
  }

  /// Re-downloads [sub], keeping ids (and thus favorites and the current
  /// selection) of servers that are still present.
  Future<Subscription> refresh(Subscription sub) async {
    final fetched = await _ref.read(subscriptionFetcherProvider).fetch(sub.url);
    final existing = (_ref.read(serversProvider).value ?? const [])
        .where((s) => s.subscriptionId == sub.id)
        .toList();
    final meta = fetched.meta;
    final updated = Subscription(
      id: sub.id,
      name: sub.name,
      url: sub.url,
      updatedAt: clock.now(),
      updateInterval: sub.updateInterval,
      autoUpdate: sub.autoUpdate,
      usage: meta.usage ?? sub.usage,
      supportUrl: meta.supportUrl ?? sub.supportUrl,
    );
    await _ref
        .read(serverRepositoryProvider)
        .replaceForSubscription(
          sub.id,
          _merge(sub.id, fetched.outcome.servers, existing: existing),
        );
    await _ref.read(subscriptionRepositoryProvider).upsert(updated);
    return updated;
  }

  /// Refreshes every subscription whose interval has elapsed. Failures are
  /// swallowed (the next tick retries).
  Future<int> refreshDue() async {
    if (!_ref.read(settingsProvider).autoUpdateSubscriptions) return 0;
    final subs = _ref.read(subscriptionsProvider).value ?? const [];
    final now = clock.now();
    var count = 0;
    for (final s in subs) {
      if (!s.autoUpdate) continue;
      final last = s.updatedAt;
      if (last != null && now.difference(last) < s.updateInterval) continue;
      try {
        await refresh(s);
        count++;
      } on SubscriptionFetchException {
        // offline or provider down
      }
    }
    return count;
  }

  List<ServerProfile> _merge(
    String subscriptionId,
    List<ServerItem> items, {
    required List<ServerProfile> existing,
  }) {
    final byIdentity = <String, ServerProfile>{for (final s in existing) s.identity: s};
    final used = <String>{};
    return [
      for (var i = 0; i < items.length; i++)
        () {
          final draft = ServerProfile(
            id: '',
            name: items[i].name,
            outbound: items[i].outbound,
            subscriptionId: subscriptionId,
            sortIndex: i,
          );
          final old = byIdentity[draft.identity];
          final reuse = old != null && used.add(old.id);
          return draft.copyWith(id: reuse ? old.id : newId(), favorite: reuse && old.favorite);
        }(),
    ];
  }
}

/// Periodically refreshes due subscriptions while the app runs.
final subscriptionAutoUpdaterProvider = Provider<void>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  // First pass shortly after launch, then every 15 minutes.
  final first = Timer(const Duration(seconds: 5), service.refreshDue);
  final periodic = Timer.periodic(const Duration(minutes: 15), (_) => service.refreshDue());
  ref.onDispose(() {
    first.cancel();
    periodic.cancel();
  });
});
