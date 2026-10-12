import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/decorations.dart';
import '../../widgets/feedback.dart';
import '../../widgets/page_scaffold.dart';

/// Living style guide: every design-system primitive in one place.
class DesignSystemPage extends StatelessWidget {
  const DesignSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    var i = 0;
    Widget item(Widget w) => StaggeredEntrance(index: i++, child: w);

    return PageScaffold(
      title: l10n.dsTitle,
      opaque: true,
      leading: AppIconButton(icon: LucideIcons.arrowLeft, onPressed: () => context.pop()),
      slivers: [
        PagePadding(
          child: SliverList.list(
            children: [
              item(SectionHeader(l10n.dsColors.toUpperCase())),
              item(
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _Swatch(gradient: c.accentGradient, label: 'Accent'),
                    _Swatch(color: c.surface, label: 'Surface'),
                    _Swatch(color: c.surfaceElevated, label: 'Elevated'),
                    _Swatch(color: c.success, label: 'Success'),
                    _Swatch(color: c.warning, label: 'Warning'),
                    _Swatch(color: c.danger, label: 'Danger'),
                    _Swatch(color: c.info, label: 'Info'),
                    _Swatch(color: c.idle, label: 'Idle'),
                  ],
                ),
              ),
              item(SectionHeader(l10n.dsTypography.toUpperCase())),
              item(
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GradientMask(child: Text('128 Mb/s', style: text.displayMedium)),
                      Text(l10n.dsTypographySample, style: text.headlineSmall),
                      Text(l10n.dsTypographySample, style: text.titleMedium),
                      Text(l10n.dsTypographySample, style: text.bodyLarge),
                      Text(l10n.dsTypographySample, style: text.bodyMedium),
                      Text(l10n.dsTypographySample.toUpperCase(), style: text.labelSmall),
                    ],
                  ),
                ),
              ),
              item(SectionHeader(l10n.dsButtons.toUpperCase())),
              item(
                GradientButton(
                  label: l10n.dsPrimaryAction,
                  icon: LucideIcons.power600,
                  expand: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              item(
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    SoftButton(
                      label: l10n.dsSecondaryAction,
                      icon: LucideIcons.download,
                      onPressed: () {},
                    ),
                    SoftButton(
                      label: l10n.dsAccentAction,
                      icon: LucideIcons.zap,
                      tone: SoftButtonTone.accent,
                      onPressed: () {},
                    ),
                    SoftButton(
                      label: l10n.dsDangerAction,
                      icon: LucideIcons.trash2,
                      tone: SoftButtonTone.danger,
                      onPressed: () {},
                    ),
                    AppIconButton(icon: LucideIcons.qrCode, onPressed: () {}),
                    AppIconButton(icon: LucideIcons.clipboardPaste, onPressed: () {}),
                  ],
                ),
              ),
              item(SectionHeader(l10n.dsCards.toUpperCase())),
              item(_cardDemo(context, AppCardVariant.solid, l10n.dsCardSolid)),
              const SizedBox(height: AppSpacing.md),
              item(_cardDemo(context, AppCardVariant.elevated, l10n.dsCardElevated)),
              const SizedBox(height: AppSpacing.md),
              item(_cardDemo(context, AppCardVariant.glass, l10n.dsCardGlass)),
              const SizedBox(height: AppSpacing.md),
              item(_cardDemo(context, AppCardVariant.solid, l10n.dsCardSelected, selected: true)),
              item(SectionHeader(l10n.dsStatus.toUpperCase())),
              item(
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    StatusPill(label: l10n.statusDisconnected, color: c.idle),
                    StatusPill(label: l10n.statusConnecting, color: c.warning, pulse: true),
                    StatusPill(label: l10n.statusConnected, color: c.success),
                    StatusPill(label: l10n.statusError, color: c.danger),
                    StatusPill(label: '42 ms', color: c.accentStart, icon: LucideIcons.zap600),
                  ],
                ),
              ),
              item(SectionHeader(l10n.dsFeedback.toUpperCase())),
              item(
                const AppCard(
                  child: Row(
                    children: [
                      Skeleton(width: 40, height: 40),
                      SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Skeleton(width: 140, height: 14),
                            SizedBox(height: AppSpacing.sm),
                            Skeleton(width: 90, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              item(
                AppCard(
                  child: EmptyState(
                    icon: LucideIcons.cloudOff300,
                    title: l10n.serversEmptyTitle,
                    message: l10n.serversEmptyBody,
                    action: SoftButton(
                      label: l10n.retry,
                      tone: SoftButtonTone.accent,
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardDemo(
    BuildContext context,
    AppCardVariant variant,
    String title, {
    bool selected = false,
  }) {
    return AppCard(
      variant: variant,
      selected: selected,
      onTap: () {},
      child: Row(
        children: [
          IconBadge(icon: LucideIcons.layers, gradient: selected),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(context.l10n.dsCardBody, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({this.color, this.gradient, required this.label});

  final Color? color;
  final Gradient? gradient;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: c.border),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
