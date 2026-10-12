import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'application/di.dart';
import 'application/settings/settings_controller.dart';
import 'core/platform.dart';
import 'data/storage/database.dart';
import 'data/storage/field_cipher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppPlatform.detect().isDesktop) {
    await _initWindow();
  }

  final (prefs, cipher) = await (
    SharedPreferences.getInstance(),
    FieldCipher.open(const SecureKeyStore()),
  ).wait;
  // App-private directory (not Documents) keeps the database out of user folders.
  final db = AppDatabase(
    driftDatabase(
      name: 'aurora',
      native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        fieldCipherProvider.overrideWithValue(cipher),
        databaseProvider.overrideWithValue(db),
      ],
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
