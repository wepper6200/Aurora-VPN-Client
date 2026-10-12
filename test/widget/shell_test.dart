import 'package:aurora_vpn/core/platform.dart';
import 'package:aurora_vpn/presentation/shell/window_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('android layout uses a bottom navigation bar', (tester) async {
    await pumpApp(tester, prefs: {'settings.language': 'en'});

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(WindowTitleBar), findsNothing);
  });

  testWidgets('windows layout uses a rail and a custom title bar', (tester) async {
    await pumpApp(
      tester,
      platform: AppPlatform.windows,
      size: const Size(460, 800),
      prefs: {'settings.language': 'en'},
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(WindowTitleBar), findsOneWidget);
  });

  testWidgets('tabs switch between pages', (tester) async {
    await pumpApp(tester, prefs: {'settings.language': 'en'});

    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();
    expect(find.text('No servers yet'), findsOneWidget);

    // The previous tab stays mounted but must be fully faded out.
    final homeFade = tester.widget<FadeTransition>(
      find.ancestor(of: find.text('No server selected'), matching: find.byType(FadeTransition)).first,
    );
    expect(homeFade.opacity.value, 0);

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('theme and language can be changed in settings', (tester) async {
    await pumpApp(tester, prefs: {'settings.language': 'en'});

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(find.text('Theme'))).brightness, Brightness.dark);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Theme'))).brightness, Brightness.light);

    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsWidgets);
    expect(find.text('Тема'), findsOneWidget);
  });
}
