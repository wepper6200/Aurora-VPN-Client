import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../application/settings/settings_controller.dart';
import '../../../core/l10n.dart';
import '../../../domain/settings/app_settings.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_card.dart';
import '../../widgets/decorations.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/settings_tile.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return PageScaffold(
      title: l10n.settingsTitle,
      slivers: [
        PagePadding(
          child: SliverList.list(
            children: [
              SectionHeader(l10n.settingsAppearance.toUpperCase()),
              _ChoiceCard<ThemePreference>(
                icon: LucideIcons.palette,
                title: l10n.settingsTheme,
                value: settings.theme,
                onChanged: controller.setTheme,
                options: {
                  ThemePreference.system: l10n.themeSystem,
                  ThemePreference.light: l10n.themeLight,
                  ThemePreference.dark: l10n.themeDark,
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _ChoiceCard<LanguagePreference>(
                icon: LucideIcons.languages,
                title: l10n.settingsLanguage,
                value: settings.language,
                onChanged: controller.setLanguage,
                options: {
                  LanguagePreference.system: l10n.languageSystem,
                  LanguagePreference.en: l10n.languageEnglish,
                  LanguagePreference.ru: l10n.languageRussian,
                },
              ),
              SectionHeader(l10n.settingsAbout.toUpperCase()),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: LucideIcons.swatchBook,
                    title: l10n.settingsDesignSystem,
                    subtitle: l10n.settingsDesignSystemSubtitle,
                    iconColor: context.colors.accentEnd,
                    onTap: () => context.go(AppRoutes.designSystem),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card with a title row and a full-width segmented selector.
class _ChoiceCard<T> extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, size: 36),
              const SizedBox(width: AppSpacing.lg),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [
              for (final e in options.entries)
                ButtonSegment<T>(value: e.key, label: Text(e.value, maxLines: 1)),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}
