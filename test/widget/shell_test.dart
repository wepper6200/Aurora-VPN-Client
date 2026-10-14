import 'package:aurora_vpn/application/settings/settings_controller.dart';
import 'package:aurora_vpn/core/platform.dart';
import 'package:aurora_vpn/domain/settings/app_settings.dart';
import 'package:aurora_vpn/presentation/theme/app_colors.dart';
import 'package:aurora_vpn/presentation/shell/window_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  const en = {'settings.language': 'en'};

  testWidgets('android layout uses a bottom navigation bar', (tester) async {
    await pumpApp(tester, prefs: en);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(WindowTitleBar), findsNothing);
  });

  testWidgets('windows layout uses a rail and a custom title bar', (tester) async {
    await pumpApp(tester, platform: AppPlatform.windows, size: const Size(460, 800), prefs: en);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(WindowTitleBar), findsOneWidget);
  });

  testWidgets('tabs switch and the previous tab fades out', (tester) async {
    await pumpApp(tester, prefs: en);

    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();
    expect(find.text('Search by name, address or protocol'), findsOneWidget);

    // The previous tab stays mounted but must be fully faded out.
    final branchOpacity = find
        .ancestor(of: find.text('Tap to connect'), matching: find.byType(AnimatedOpacity))
        .first;
    final homeFade = tester.widget<FadeTransition>(
      find.descendant(of: branchOpacity, matching: find.byType(FadeTransition)).first,
    );
    expect(homeFade.opacity.value, 0);

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('first launch shows onboarding and finishes on the home tab', (tester) async {
    await pumpApp(tester, prefs: {...en, 'settings.onboardingDone': false});

    expect(find.text('Pick a look'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your VPN, your rules'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Add a subscription'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Tap to connect'), findsOneWidget);
  });

  testWidgets('the style picked during onboarding is applied and saved', (tester) async {
    final container = await pumpApp(tester, prefs: {...en, 'settings.onboardingDone': false});

    await tester.tap(find.text('Liquid Glass'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).designStyle, DesignStyle.glass);
    expect(Theme.of(tester.element(find.text('Pick a look'))).extension<AppColors>()!.isGlass, true);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    // Liquid Glass replaces the Material navigation bar with a glass capsule.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Servers'), findsOneWidget);
  });

  testWidgets('onboarding can be skipped', (tester) async {
    await pumpApp(tester, prefs: {...en, 'settings.onboardingDone': false});

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
