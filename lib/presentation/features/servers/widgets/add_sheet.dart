import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n.dart';
import '../../../../core/platform.dart';
import '../../../router/app_router.dart';
import '../../../util/import_feedback.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/dialogs.dart';
import '../../../widgets/settings_tile.dart';

/// Bottom sheet with every way to add servers.
Future<void> showAddSheet(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final platform = ref.read(appPlatformProvider);
  final c = context.colors;

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      void close(void Function() then) {
        Navigator.of(sheetContext).pop();
        then();
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.addSheetTitle, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: LucideIcons.link,
                    title: l10n.addFromUrl,
                    subtitle: l10n.addFromUrlSub,
                    onTap: () => close(() => context.go(AppRoutes.newSubscription)),
                  ),
                  SettingsTile(
                    icon: LucideIcons.clipboardPaste,
                    iconColor: c.info,
                    title: l10n.addFromClipboard,
                    subtitle: l10n.addFromClipboardSub,
                    onTap: () => close(() => importFromClipboard(context, ref)),
                  ),
                  if (platform.isMobile)
                    SettingsTile(
                      icon: LucideIcons.scanQrCode,
                      iconColor: c.accentEnd,
                      title: l10n.addScanQr,
                      subtitle: l10n.addScanQrSub,
                      onTap: () => close(() => context.go(AppRoutes.scanQr)),
                    ),
                  SettingsTile(
                    icon: LucideIcons.squarePen,
                    iconColor: c.warning,
                    title: l10n.addManual,
                    subtitle: l10n.addManualSub,
                    onTap: () => close(() => context.go(AppRoutes.newServer)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// A lone subscription URL opens the subscription form (to name it and pick
/// the interval); anything else — share links, JSON, YAML — is imported.
Future<void> importFromClipboard(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
  if (!context.mounted) return;
  if (text.isEmpty) {
    showToast(context, l10n.clipboardEmpty);
    return;
  }
  final uri = Uri.tryParse(text);
  if (!text.contains('\n') && uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    context.go(Uri(path: AppRoutes.newSubscription, queryParameters: {'url': text}).toString());
    return;
  }
  await importWithFeedback(context, ref, text);
}
