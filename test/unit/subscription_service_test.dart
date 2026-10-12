import 'dart:convert';

import 'package:aurora_vpn/application/di.dart';
import 'package:aurora_vpn/application/import/import_service.dart';
import 'package:aurora_vpn/application/servers/servers_controller.dart';
import 'package:aurora_vpn/application/settings/settings_controller.dart';
import 'package:aurora_vpn/application/subscriptions/subscription_service.dart';
import 'package:aurora_vpn/data/mock/in_memory_repositories.dart';
import 'package:aurora_vpn/data/subscriptions/subscription_fetcher.dart';
import 'package:aurora_vpn/domain/subscriptions/subscription.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const uuid = '11111111-2222-4333-8444-555555555555';

String link(String name, String host) => 'vless://$uuid@$host:443?security=tls#$name';

/// Serves whatever [body] currently holds, and counts requests.
class FakePanel {
  String body = '';
  Map<String, String> headers = {};
  int status = 200;
  final requests = <http.Request>[];

  http.Client get client => MockClient((req) async {
    requests.add(req);
    return http.Response(base64.encode(utf8.encode(body)), status, headers: headers);
  });
}

Future<(ProviderContainer, FakePanel, InMemoryServerRepository)> setUpContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final panel = FakePanel();
  final servers = InMemoryServerRepository();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      serverRepositoryProvider.overrideWithValue(servers),
      subscriptionRepositoryProvider.overrideWithValue(
        InMemorySubscriptionRepository(const [], servers),
      ),
      subscriptionFetcherProvider.overrideWithValue(
        SubscriptionFetcher(userAgent: 'AuroraVPN/test', client: panel.client),
      ),
    ],
  );
  // Keep the streams alive like the UI does.
  container.listen(serversProvider, (_, _) {});
  container.listen(subscriptionsProvider, (_, _) {});
  await pumpEventQueue();
  return (container, panel, servers);
}

void main() {
  test('add: names from headers, applies interval and quota, sends the UA', () async {
    final (c, panel, _) = await setUpContainer();
    addTearDown(c.dispose);
    panel
      ..body = [link('A', 'a.example.com'), link('B', 'b.example.com')].join('\n')
      ..headers = {
        'profile-title': 'Panel',
        'profile-update-interval': '3',
        'subscription-userinfo': 'upload=1; download=2; total=100',
      };

    final sub = await c.read(subscriptionServiceProvider).add(url: 'https://p.example.com/s');
    await pumpEventQueue();

    expect(sub.name, 'Panel');
    expect(sub.updateInterval, const Duration(hours: 3));
    expect(sub.usage!.remaining, 97);
    expect(panel.requests.single.headers['User-Agent'], 'AuroraVPN/test');
    final list = c.read(serversProvider).value!;
    expect(list.map((s) => s.name), ['A', 'B']);
    expect(list.every((s) => s.subscriptionId == sub.id), isTrue);
  });

  test('refresh keeps ids and favorites of servers that are still present', () async {
    final (c, panel, repo) = await setUpContainer();
    addTearDown(c.dispose);
    panel.body = [link('A', 'a.example.com'), link('B', 'b.example.com')].join('\n');
    final sub = await c.read(subscriptionServiceProvider).add(url: 'https://p.example.com/s');
    await pumpEventQueue();

    final a = c.read(serversProvider).value!.firstWhere((s) => s.name == 'A');
    await repo.upsert(a.copyWith(favorite: true));
    await c.read(selectedServerIdProvider.notifier).select(a.id);
    await pumpEventQueue();

    // B removed, C added, A moved to the end.
    panel.body = [link('C', 'c.example.com'), link('A', 'a.example.com')].join('\n');
    await c.read(subscriptionServiceProvider).refresh(sub);
    await pumpEventQueue();

    final after = c.read(serversProvider).value!;
    expect(after.map((s) => s.name), ['C', 'A']);
    final a2 = after.firstWhere((s) => s.name == 'A');
    expect(a2.id, a.id);
    expect(a2.favorite, isTrue);
    expect(after.firstWhere((s) => s.name == 'C').favorite, isFalse);
    expect(c.read(selectedServerProvider)!.id, a.id);
  });

  test('refreshDue honors per-subscription interval and the global switch', () async {
    final (c, panel, _) = await setUpContainer();
    addTearDown(c.dispose);
    panel.body = link('A', 'a.example.com');
    final repo = c.read(subscriptionRepositoryProvider);
    final now = clock.now();
    await repo.upsert(
      Subscription(
        id: 'fresh',
        name: 'F',
        url: 'https://f.example.com',
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
    );
    await repo.upsert(
      Subscription(
        id: 'stale',
        name: 'S',
        url: 'https://s.example.com',
        updatedAt: now.subtract(const Duration(hours: 13)),
      ),
    );
    await repo.upsert(
      Subscription(
        id: 'manual',
        name: 'M',
        url: 'https://m.example.com',
        autoUpdate: false,
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    );
    await pumpEventQueue();

    expect(await c.read(subscriptionServiceProvider).refreshDue(), 1);
    expect(panel.requests.single.url.host, 's.example.com');

    await c
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(autoUpdateSubscriptions: false));
    panel.requests.clear();
    await repo.upsert(
      Subscription(
        id: 'stale2',
        name: 'S2',
        url: 'https://s2.example.com',
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    );
    await pumpEventQueue();
    expect(await c.read(subscriptionServiceProvider).refreshDue(), 0);
    expect(panel.requests, isEmpty);
  });

  test('fetch failures surface as SubscriptionFetchException', () async {
    final (c, panel, _) = await setUpContainer();
    addTearDown(c.dispose);
    panel.status = 403;
    await expectLater(
      c.read(subscriptionServiceProvider).add(url: 'https://p.example.com/s'),
      throwsA(isA<SubscriptionFetchException>().having((e) => e.message, 'message', 'HTTP 403')),
    );
    panel
      ..status = 200
      ..body = 'just some text';
    await expectLater(
      c.read(subscriptionServiceProvider).add(url: 'https://p.example.com/s'),
      throwsA(isA<SubscriptionFetchException>()),
    );
  });

  test('import: links become manual servers, URLs become subscriptions', () async {
    final (c, panel, _) = await setUpContainer();
    addTearDown(c.dispose);
    panel.body = link('Remote', 'r.example.com');

    final report = await c
        .read(importServiceProvider)
        .importText(
          [
            link('Manual 1', 'm1.example.com'),
            'trojan://pw@m2.example.com:443#Manual%202',
            'happ://add/https://sub.example.com/x',
            'vless://broken',
          ].join('\n'),
        );
    await pumpEventQueue();

    expect(report.servers, 2);
    expect(report.subscriptions, 1);
    expect(report.failures, hasLength(1));
    final all = c.read(serversProvider).value!;
    expect(all.where((s) => s.subscriptionId == null).map((s) => s.name), ['Manual 1', 'Manual 2']);
    expect(all.where((s) => s.subscriptionId != null).map((s) => s.name), ['Remote']);

    // The same subscription URL isn't added twice.
    final again = await c.read(importServiceProvider).importText('https://sub.example.com/x');
    expect(again.subscriptions, 0);
  });
}
