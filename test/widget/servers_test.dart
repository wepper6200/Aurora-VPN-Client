import 'dart:convert';

import 'package:aurora_vpn/application/di.dart';
import 'package:aurora_vpn/application/servers/servers_controller.dart';
import 'package:aurora_vpn/data/mock/mock_vpn_core.dart';
import 'package:aurora_vpn/data/subscriptions/subscription_fetcher.dart';
import 'package:aurora_vpn/presentation/features/servers/widgets/server_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/test_app.dart';

Future<void> _openServers(WidgetTester tester) async {
  await tester.tap(find.text('Servers'));
  await tester.pumpAndSettle();
}

void main() {
  const en = {'settings.language': 'en'};

  testWidgets('servers are grouped by subscription with a manual group', (tester) async {
    await pumpApp(tester, prefs: en, size: const Size(412, 1600));
    await _openServers(tester);

    expect(find.text('Nebula Cloud'), findsWidgets);
    expect(find.text('Orbit Lab'), findsOneWidget);
    expect(find.text('My configs'), findsOneWidget);
    expect(find.byType(ServerTile), findsNWidgets(7));
  });

  testWidgets('search and favorites filter the list', (tester) async {
    await pumpApp(tester, prefs: en, size: const Size(412, 1600));
    await _openServers(tester);

    await tester.enterText(find.byType(TextField), 'hysteria');
    await tester.pumpAndSettle();
    expect(find.byType(ServerTile), findsOneWidget);
    expect(find.widgetWithText(ServerTile, 'Finland · Helsinki'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nothing-matches');
    await tester.pumpAndSettle();
    expect(find.text('Nothing found'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.byType(ServerTile), findsOneWidget);
    // The home tab (also mounted) shows the same name, so scope to the tile.
    expect(find.widgetWithText(ServerTile, 'Germany · Frankfurt'), findsOneWidget);
  });

  testWidgets('tapping a server selects it and returns to the home tab', (tester) async {
    final container = await pumpApp(tester, prefs: en, size: const Size(412, 1600));
    await _openServers(tester);

    await tester.tap(find.text('Netherlands · Amsterdam'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(container.read(selectedServerProvider)?.id, 's2');
    // Remembered for the quick settings tile and the home-screen widget.
    final core = container.read(vpnCoreProvider) as MockVpnCoreController;
    expect(core.remembered.last.serverId, 's2');
    expect(core.remembered.last.label, 'Netherlands · Amsterdam');

    // Back on Home without touching the tab bar.
    expect(find.text('Tap to connect'), findsOneWidget);
    final branch = find
        .ancestor(of: find.text('Tap to connect'), matching: find.byType(AnimatedOpacity))
        .first;
    final homeFade = tester.widget<FadeTransition>(
      find.descendant(of: branch, matching: find.byType(FadeTransition)).first,
    );
    expect(homeFade.opacity.value, 1);
  });

  testWidgets('latency test runs in parallel and sorting uses the result', (tester) async {
    final container = await pumpApp(tester, prefs: en, size: const Size(412, 1600));
    await _openServers(tester);

    await tester.tap(find.byTooltip('Test latency'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      container.read(latencyProvider).values.where((r) => r.state == LatencyState.testing),
      hasLength(7),
    );

    await pumpFor(tester, const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('48 ms'), findsOneWidget);
    expect(find.text('timeout'), findsOneWidget);

    container.read(serverQueryProvider.notifier).setSort(ServerSort.latency);
    await tester.pumpAndSettle();
    final names = tester
        .widgetList<ServerTile>(find.byType(ServerTile))
        .map((t) => t.server.name)
        .toList();
    // Within the first subscription: 48 < 63 < 112 < 187.
    expect(names.take(4), [
      'Germany · Frankfurt',
      'Netherlands · Amsterdam',
      'Finland · Helsinki',
      'United States · New York',
    ]);
  });

  Future<void> openNewSubscription(WidgetTester tester) async {
    await _openServers(tester);
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subscription link'));
    await tester.pumpAndSettle();
  }

  testWidgets('adding a subscription fetches it and stores its servers', (tester) async {
    final links = [
      'vless://00000000-0000-4000-8000-000000000001@a.example.com:443?security=tls&type=ws&path=%2Fx#Alpha',
      'trojan://secret@b.example.com:443#Beta',
    ].join('\n');
    final fetcher = SubscriptionFetcher(
      userAgent: 'test',
      client: MockClient(
        (req) async => http.Response(
          base64.encode(utf8.encode(links)),
          200,
          headers: {
            'profile-title': 'base64:${base64.encode(utf8.encode('Fresh Sub'))}',
            'subscription-userinfo': 'upload=0; download=1073741824; total=10737418240',
            'profile-update-interval': '6',
          },
        ),
      ),
    );
    final container = await pumpApp(
      tester,
      prefs: en,
      size: const Size(412, 1000),
      fetcher: fetcher,
    );
    await openNewSubscription(tester);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid http(s) link'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'https://new.example.com/sub/abc');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final sub = container
        .read(subscriptionsProvider)
        .value!
        .singleWhere((s) => s.name == 'Fresh Sub');
    expect(sub.updateInterval, const Duration(hours: 6));
    expect(sub.usage!.total, 10737418240);
    final servers = container
        .read(serversProvider)
        .value!
        .where((s) => s.subscriptionId == sub.id)
        .map((s) => s.name);
    expect(servers, ['Alpha', 'Beta']);
    expect(find.text('Search by name, address or protocol'), findsOneWidget);
  });

  testWidgets('a failing subscription shows the reason and stays on the form', (tester) async {
    await pumpApp(tester, prefs: en, size: const Size(412, 1000));
    await openNewSubscription(tester);

    await tester.enterText(find.byType(TextFormField).first, 'https://down.example.com/sub');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('The subscription server returned an error (404).'), findsOneWidget);
    expect(find.text('New subscription'), findsOneWidget);
  });
}
