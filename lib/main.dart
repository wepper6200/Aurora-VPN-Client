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
import 'presentation/shell/desktop_integration.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppPlatform.detect().isDesktop) {
    // Clean up after a previous run that died with the core still running
    // (orphaned sing-box/xray, system proxy left on).
    await windowsCore().recover().catchError((_) {});
    await _initWindow(show: !args.contains(WindowsAutostart.minimizedFlag));
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

Future<void> _initWindow({required bool show}) async {
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
    // Autostart launches straight into the tray.
    if (!show) return;
    await windowManager.show();
    await windowManager.focus();
  });
}
