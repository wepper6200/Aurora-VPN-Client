import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppPlatform {
  android,
  windows,
  other;

  bool get isDesktop => this == AppPlatform.windows;
  bool get isMobile => this == AppPlatform.android;

  static AppPlatform detect() {
    if (kIsWeb) return AppPlatform.other;
    if (Platform.isAndroid) return AppPlatform.android;
    if (Platform.isWindows) return AppPlatform.windows;
    return AppPlatform.other;
  }
}

/// Current platform. Overridden in tests to render either layout.
final appPlatformProvider = Provider<AppPlatform>((ref) => AppPlatform.detect());

/// Whether the native Windows shell (tray, close-to-tray, autostart) is
/// attached. Tests render the Windows layout without those plugins.
final desktopShellProvider = Provider<bool>(
  (ref) => ref.watch(appPlatformProvider) == AppPlatform.windows,
);
