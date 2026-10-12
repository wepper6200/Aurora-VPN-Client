import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../application/settings/settings_controller.dart';
import '../../application/vpn/vpn_controller.dart';
import '../../core/l10n.dart';
import '../../domain/vpn/vpn_core.dart';

/// Windows-only glue: tray icon + menu, close-to-tray and the autostart
/// registry entry. Wraps the app; renders nothing itself.
class DesktopIntegration extends ConsumerStatefulWidget {
  const DesktopIntegration({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DesktopIntegration> createState() => _DesktopIntegrationState();
}

class _DesktopIntegrationState extends ConsumerState<DesktopIntegration>
    with TrayListener, WindowListener {
  static const _connectKey = 'connect';
  static const _showKey = 'show';
  static const _quitKey = 'quit';
  bool _quitting = false;

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    unawaited(windowManager.setPreventClose(true));
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshTray());
    unawaited(WindowsAutostart.apply(ref.read(settingsProvider).launchAtStartup));
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _refreshTray() async {
    if (!mounted) return;
    final l10n = context.l10n;
    final vpn = ref.read(vpnStateProvider);
    final active = vpn.isActive;
    // Colour mark while the tunnel is up, grey when it is off.
    await trayManager.setIcon(
      vpn.status == VpnStatus.connected ? 'assets/tray/tray.ico' : 'assets/tray/tray_off.ico',
    );
    await trayManager.setToolTip(
      '${l10n.appTitle} — ${active ? l10n.statusConnected : l10n.statusDisconnected}',
    );
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: _connectKey, label: active ? l10n.trayDisconnect : l10n.trayConnect),
          MenuItem(key: _showKey, label: l10n.trayShow),
          MenuItem.separator(),
          MenuItem(key: _quitKey, label: l10n.trayQuit),
        ],
      ),
    );
  }

  Future<void> _show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    if (_quitting) return;
    _quitting = true;
    // Always stop the core first: it restores the system proxy.
    if (ref.read(vpnStateProvider).status != VpnStatus.disconnected) {
      await ref
          .read(vpnStateProvider.notifier)
          .disconnect()
          .timeout(const Duration(seconds: 6), onTimeout: () {});
    }
    await trayManager.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  // --- TrayListener -------------------------------------------------------------

  @override
  void onTrayIconMouseDown() => unawaited(_show());

  @override
  void onTrayIconRightMouseDown() => unawaited(trayManager.popUpContextMenu());

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case _connectKey:
        unawaited(ref.read(vpnStateProvider.notifier).toggle());
      case _showKey:
        unawaited(_show());
      case _quitKey:
        unawaited(_quit());
    }
  }

  // --- WindowListener -------------------------------------------------------------

  /// The close button hides to the tray; "Quit" lives in the tray menu.
  @override
  void onWindowClose() {
    if (!_quitting) unawaited(windowManager.hide());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(vpnStateProvider.select((s) => s.status), (_, _) => _refreshTray());
    ref.listen(settingsProvider.select((s) => s.language), (_, _) => _refreshTray());
    ref.listen(
      settingsProvider.select((s) => s.launchAtStartup),
      (_, enabled) => WindowsAutostart.apply(enabled),
    );
    return widget.child;
  }
}

/// `HKCU\…\Run` entry that starts the app minimized to the tray at sign-in.
abstract final class WindowsAutostart {
  static const _key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const _name = 'AuroraVPN';
  static const minimizedFlag = '--minimized';

  static Future<void> apply(bool enabled) async {
    if (!Platform.isWindows) return;
    try {
      if (enabled) {
        final command = '"${Platform.resolvedExecutable}" $minimizedFlag';
        await Process.run('reg', ['add', _key, '/v', _name, '/t', 'REG_SZ', '/d', command, '/f']);
      } else {
        await Process.run('reg', ['delete', _key, '/v', _name, '/f']);
      }
    } catch (_) {
      // Not fatal; the setting simply has no effect.
    }
  }
}

/// Relaunches the app elevated (TUN needs administrator rights). The current
/// instance exits first so the single-instance lock is free.
Future<void> restartAsAdministrator() async {
  final exe = Platform.resolvedExecutable.replaceAll("'", "''");
  await Process.start('powershell', [
    '-NoProfile',
    '-WindowStyle',
    'Hidden',
    '-Command',
    "Start-Sleep -Milliseconds 800; Start-Process -FilePath '$exe' -Verb RunAs",
  ], mode: ProcessStartMode.detached);
  await windowManager.setPreventClose(false);
  await windowManager.destroy();
}
