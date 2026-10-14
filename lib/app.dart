import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/di.dart';
import 'application/logs/logs_controller.dart';
import 'application/settings/settings_controller.dart';
import 'application/subscriptions/subscription_service.dart';
import 'application/vpn/vpn_controller.dart';
import 'core/clock.dart';
import 'core/l10n.dart';
import 'core/platform.dart';
import 'data/vpn/android_vpn_controller.dart';
import 'domain/settings/app_settings.dart';
import 'presentation/router/app_router.dart';
import 'presentation/shell/desktop_integration.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/util/import_feedback.dart';
import 'presentation/widgets/dialogs.dart';

class AuroraApp extends ConsumerStatefulWidget {
  const AuroraApp({super.key});

  @override
  ConsumerState<AuroraApp> createState() => _AuroraAppState();
}

class _AuroraAppState extends ConsumerState<AuroraApp> {
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    _links = ref.read(deepLinksProvider).listen(_onDeepLink);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(appPlatformProvider) == AppPlatform.android) unawaited(_reportPreviousCrash());
      unawaited(ref.read(vpnStateProvider.notifier).autoConnect().catchError((_) {}));
    });
  }

  /// Surfaces the last crash (JVM or core) in the Logs tab so it can be
  /// copied without adb.
  Future<void> _reportPreviousCrash() async {
    final report = await AndroidVpnController.takeLastCrash();
    final context = rootNavigatorKey.currentContext;
    if (report == null || context == null || !context.mounted) return;
    final l10n = context.l10n;
    ref.read(logsProvider.notifier).addReport(ref.read(nowProvider)(), l10n.crashTitle, report);
    showToast(context, l10n.crashPrevious, error: true);
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  /// vless://…, happ://add/…, etc. opened from another app or the browser.
  Future<void> _onDeepLink(Uri uri) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    await importWithFeedback(context, ref, uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    // Collect core logs from launch, not from the first visit to the Logs tab.
    ref.listen(logsProvider, (_, _) {});
    ref.listen(subscriptionAutoUpdaterProvider, (_, _) {});
    final code = settings.language.code;

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.of(settings.designStyle, Brightness.light),
      darkTheme: AppTheme.of(settings.designStyle, Brightness.dark),
      themeMode: switch (settings.theme) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      themeAnimationDuration: const Duration(milliseconds: 350),
      locale: code == null ? null : Locale(code),
      // Windows tray/close-to-tray glue needs localizations, so it sits inside.
      builder: (context, child) =>
          ref.read(desktopShellProvider) ? DesktopIntegration(child: child!) : child!,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
