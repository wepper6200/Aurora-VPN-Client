@Tags(['golden'])
library;

import 'package:aurora_vpn/core/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// Screen goldens. Regenerate after intentional UI changes:
///   flutter test --update-goldens --tags golden
void main() {
  setUpAll(loadAppFonts);

  const variants = <String, ({AppPlatform platform, Size size, String theme})>{
    'android_dark': (platform: AppPlatform.android, size: Size(412, 892), theme: 'dark'),
    'android_light': (platform: AppPlatform.android, size: Size(412, 892), theme: 'light'),
    'windows_dark': (platform: AppPlatform.windows, size: Size(460, 800), theme: 'dark'),
  };

  const tabs = {'home': null, 'servers': 1, 'settings': 4};

  for (final v in variants.entries) {
    for (final tab in tabs.entries) {
      testWidgets('${v.key} ${tab.key}', (tester) async {
        await pumpApp(
          tester,
          platform: v.value.platform,
          size: v.value.size,
          prefs: {'settings.language': 'ru', 'settings.theme': v.value.theme},
        );
        if (tab.value != null) {
          await _selectTab(tester, tab.value!, v.value.platform);
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${v.key}_${tab.key}.png'),
        );
      });
    }
  }

  testWidgets('android_dark design_system', (tester) async {
    await pumpApp(tester, prefs: {'settings.language': 'ru', 'settings.theme': 'dark'});
    await _selectTab(tester, 4, AppPlatform.android);
    await tester.tap(find.text('Дизайн-система'));
    // Skeletons shimmer forever, so pump a fixed amount instead of settling.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    tester.view.physicalSize = const Size(412, 2000);
    // Newly revealed items run their staggered entrance (≤ 450ms + 420ms).
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/android_dark_design_system.png'),
    );
  });
}

Future<void> _selectTab(WidgetTester tester, int index, AppPlatform platform) async {
  final destinations = platform.isDesktop
      ? find.descendant(of: find.byType(NavigationRail), matching: find.byType(Icon))
      : find.byType(NavigationDestination);
  await tester.tap(destinations.at(index));
  await tester.pumpAndSettle();
}
