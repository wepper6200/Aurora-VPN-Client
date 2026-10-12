import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n.dart';
import '../../../../domain/subscriptions/subscription.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../../util/formatters.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/decorations.dart';
import '../../../widgets/usage_bar.dart';
import 'server_widgets.dart';

enum SubscriptionMenuAction { edit, update, copyLink, delete }

class SubscriptionHeader extends StatelessWidget {
  const SubscriptionHeader({
    super.key,
    required this.subscription,
    required this.serverCount,
    required this.collapsed,
    required this.updating,
    required this.onToggle,
    required this.onMenu,
  });

  final Subscription subscription;
  final int serverCount;
  final bool collapsed;
  final bool updating;
  final VoidCallback onToggle;
  final ValueChanged<SubscriptionMenuAction> onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final usage = subscription.usage;
    final days = usage?.expire == null ? null : Fmt.daysUntil(usage!.expire!);
    final meta = [
      l10n.serversCount(serverCount),
      if (subscription.updatedAt != null)
        l10n.serversUpdated(Fmt.relative(subscription.updatedAt!, l10n)),
    ].join(' · ');

    return AppCard(
      variant: AppCardVariant.elevated,
      onTap: onToggle,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: LucideIcons.layers, size: 36, color: c.accentEnd),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      meta,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.actionUpdate,
                onPressed: updating ? null : () => onMenu(SubscriptionMenuAction.update),
                icon: _Spinning(
                  spinning: updating,
                  child: Icon(LucideIcons.refreshCw, size: 18, color: c.textSecondary),
                ),
              ),
              PopupMenuButton<SubscriptionMenuAction>(
                icon: Icon(LucideIcons.ellipsisVertical, size: 20, color: c.textTertiary),
                onSelected: onMenu,
                itemBuilder: (context) => [
                  menuItem(SubscriptionMenuAction.edit, LucideIcons.pencil, l10n.actionEdit),
                  menuItem(SubscriptionMenuAction.copyLink, LucideIcons.link, l10n.actionCopyLink),
                  menuItem(
                    SubscriptionMenuAction.delete,
                    LucideIcons.trash2,
                    l10n.actionDelete,
                    color: c.danger,
                  ),
                ],
              ),
              AnimatedRotation(
                turns: collapsed ? -0.25 : 0,
                duration: AppDurations.medium,
                curve: AppCurves.standard,
                child: Icon(LucideIcons.chevronDown, size: 18, color: c.textTertiary),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          if (usage != null && !usage.unlimited) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: UsageBar(fraction: usage.usedFraction!),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    l10n.subUsedOf(Fmt.bytes(usage.used, locale), Fmt.bytes(usage.total, locale)),
                    style: theme.textTheme.labelSmall!.tabular,
                  ),
                  const Spacer(),
                  if (days != null)
                    Text(
                      days < 0 ? l10n.subExpired : l10n.subExpiresInDays(days),
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: days < 0 ? c.danger : (days <= 5 ? c.warning : c.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Spinning extends StatefulWidget {
  const _Spinning({required this.spinning, required this.child});

  final bool spinning;
  final Widget child;

  @override
  State<_Spinning> createState() => _SpinningState();
}

class _SpinningState extends State<_Spinning> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _c.repeat();
  }

  @override
  void didUpdateWidget(_Spinning old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.spinning && _c.isAnimating) {
      _c.forward(from: _c.value).then((_) => _c.reset());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(turns: _c, child: widget.child);
}
