import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../application/routing/routing_controller.dart';
import '../../../core/l10n.dart';
import '../../../core/platform.dart';
import '../../../domain/routing/routing_settings.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_card.dart';
import '../../widgets/decorations.dart';
import '../../widgets/feedback.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/settings_tile.dart';

class RoutingPage extends ConsumerWidget {
  const RoutingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final r = ref.watch(routingProvider);
    final ctrl = ref.read(routingProvider.notifier);
    final platform = ref.watch(appPlatformProvider);
    final presetsActive = r.mode == RoutingMode.rules;

    var i = 0;
    Widget item(Widget w) => StaggeredEntrance(index: i++, child: w);

    final splitSubtitle = switch (r.splitMode) {
      SplitTunnelMode.off => l10n.splitOffSub,
      SplitTunnelMode.include => l10n.splitIncludeSub(r.splitApps.length),
      SplitTunnelMode.exclude => l10n.splitExcludeSub(r.splitApps.length),
    };

    return PageScaffold(
      title: l10n.routingTitle,
      subtitle: l10n.routingSubtitle,
      slivers: [
        PagePadding(
          child: SliverList.list(
            children: [
              SectionHeader(l10n.routingMode.toUpperCase()),
              for (final (mode, icon, title, sub) in [
                (RoutingMode.global, LucideIcons.globe, l10n.routingGlobal, l10n.routingGlobalSub),
                (RoutingMode.rules, LucideIcons.split, l10n.routingRules, l10n.routingRulesSub),
                (
                  RoutingMode.direct,
                  LucideIcons.arrowRight,
                  l10n.routingDirect,
                  l10n.routingDirectSub,
                ),
              ])
                item(
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ModeCard(
                      icon: icon,
                      title: title,
                      subtitle: sub,
                      selected: r.mode == mode,
                      onTap: () => ctrl.update((s) => s.copyWith(mode: mode)),
                    ),
                  ),
                ),
              SectionHeader(l10n.routingPresets.toUpperCase()),
              item(
                AnimatedOpacity(
                  duration: AppDurations.medium,
                  opacity: presetsActive ? 1 : 0.55,
                  child: SettingsGroup(
                    children: [
                      _switchTile(
                        icon: LucideIcons.house,
                        title: l10n.presetBypassLan,
                        subtitle: l10n.presetBypassLanSub,
                        value: r.bypassLan,
                        onChanged: (v) => ctrl.update((s) => s.copyWith(bypassLan: v)),
                      ),
                      _switchTile(
                        icon: LucideIcons.mapPin,
                        title: l10n.presetRuDirect,
                        subtitle: l10n.presetRuDirectSub,
                        color: c.info,
                        value: r.ruDirect,
                        onChanged: (v) => ctrl.update((s) => s.copyWith(ruDirect: v)),
                      ),
                      _switchTile(
                        icon: LucideIcons.ban,
                        title: l10n.presetBlockAds,
                        subtitle: l10n.presetBlockAdsSub,
                        color: c.danger,
                        value: r.blockAds,
                        onChanged: (v) => ctrl.update((s) => s.copyWith(blockAds: v)),
                      ),
                    ],
                  ),
                ),
              ),
              if (!presetsActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.xs,
                    0,
                  ),
                  child: Text(l10n.presetsInactive, style: Theme.of(context).textTheme.bodySmall),
                ),
              SectionHeader(l10n.routingSplit.toUpperCase()),
              item(
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: LucideIcons.layoutGrid,
                      iconColor: c.accentEnd,
                      title: l10n.splitApps,
                      subtitle: platform.isMobile ? splitSubtitle : l10n.splitAndroidOnly,
                      onTap: platform.isMobile ? () => context.go(AppRoutes.splitApps) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? color,
  }) {
    return SettingsTile(
      icon: icon,
      iconColor: color,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

/// Radio-like card for a routing mode.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    return AppCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadii.lg,
      child: Row(
        children: [
          IconBadge(icon: icon, gradient: selected),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          AnimatedContainer(
            duration: AppDurations.medium,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected ? c.accentGradient : null,
              border: selected ? null : Border.all(color: c.textTertiary, width: 1.5),
            ),
            child: selected
                ? Icon(
                    LucideIcons.check600,
                    size: 14,
                    color: c.isDark ? const Color(0xFF071613) : Colors.white,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
