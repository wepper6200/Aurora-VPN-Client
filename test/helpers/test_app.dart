import 'dart:convert';

import 'package:aurora_vpn/app.dart';
import 'package:aurora_vpn/application/settings/settings_controller.dart';
import 'package:aurora_vpn/core/platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _fontsLoaded = false;

/// Loads every font from the app's FontManifest (Manrope, Phosphor icons,
/// Material icons) so goldens show real glyphs instead of Ahem boxes.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

/// Pumps the full app with mocked preferences and a fixed platform/size.
Future<void> pumpApp(
  WidgetTester tester, {
  AppPlatform platform = AppPlatform.android,
  Size size = const Size(412, 892),
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(instance),
        appPlatformProvider.overrideWithValue(platform),
      ],
      child: const AuroraApp(),
    ),
  );
  await tester.pumpAndSettle();
}
