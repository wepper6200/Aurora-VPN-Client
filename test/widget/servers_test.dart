import 'package:aurora_vpn/application/servers/servers_controller.dart';
import 'package:aurora_vpn/presentation/features/servers/widgets/server_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.text('MY CONFIGS'), findsOneWidget);
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

  testWidgets('tapping a server selects it for the home screen', (tester) async {
    final container = await pumpApp(tester, prefs: en, size: const Size(412, 1600));
    await _openServers(tester);

    await tester.tap(find.text('Netherlands · Amsterdam'));
    await tester.pumpAndSettle();
    expect(container.read(selectedServerProvider)?.id, 's2');

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Netherlands · Amsterdam'), findsWidgets);
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

  testWidgets('adding a subscription validates the URL and saves it', (tester) async {
    final container = await pumpApp(tester, prefs: en, size: const Size(412, 1000));
    await _openServers(tester);

    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subscription link'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid http(s) link'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'https://new.example.com/sub/abc');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final subs = container.read(subscriptionsProvider).value!;
    expect(subs.map((s) => s.name), contains('new.example.com'));
    expect(find.text('Search by name, address or protocol'), findsOneWidget);
  });
}
