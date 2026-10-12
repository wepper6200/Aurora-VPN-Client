import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'application/settings/settings_controller.dart';
import 'core/platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppPlatform.detect().isDesktop) {
    await _initWindow();
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AuroraApp(),
    ),
  );
}

Future<void> _initWindow() async {
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(460, 800),
    minimumSize: Size(420, 720),
    center: true,
    title: 'Aurora VPN',
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Colors.transparent,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
