import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../application/servers/servers_controller.dart';
import '../../../application/vpn/connection_health.dart';
import '../../../application/vpn/vpn_controller.dart';
import '../../../core/l10n.dart';
import '../../../domain/vpn/vpn_core.dart';
import '../../router/app_router.dart';
import '../../shell/app_logo.dart';
import '../../shell/desktop_integration.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/decorations.dart';
import '../../widgets/feedback.dart';
import '../../widgets/page_scaffold.dart';
import 'widgets/connect_button.dart';
import 'widgets/home_cards.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final vpn = ref.watch(vpnStateProvider);
    final server = ref.watch(selectedServerProvider);
    final serversLoading = ref.watch(serversProvider).isLoading;
    final latency = server == null ? null : ref.watch(latencyProvider)[server.id];
    final subscription = server?.subscriptionId == null
        ? null
        : ref
              .watch(subscriptionsProvider)
              .value
              ?.where((s) => s.id == server!.subscriptionId)
              .firstOrNull;

    final width = MediaQuery.sizeOf(context).width;
    final buttonSize = (width * 0.6).clamp(196.0, 260.0);

    final pill = switch (vpn.status) {
      VpnStatus.connected => StatusPill(label: l10n.statusConnected, color: c.success),
      VpnStatus.connecting => StatusPill(
        label: l10n.statusConnecting,
        color: c.warning,
        pulse: true,
      ),
      VpnStatus.disconnecting => StatusPill(
        label: l10n.statusDisconnecting,
        color: c.warning,
        pulse: true,
      ),
      VpnStatus.error => StatusPill(label: l10n.statusError, color: c.danger),
      VpnStatus.disconnected => StatusPill(label: l10n.statusDisconnected, color: c.idle),
    };

    var i = 0;
    Widget item(Widget w) => StaggeredEntrance(index: i++, child: w);

    return PageScaffold(
      title: l10n.homeTitle,
      leading: const AppLogo(size: 36),
      actions: [AnimatedSwitcher(duration: AppDurations.medium, child: pill)],
      slivers: [
        PagePadding(
          child: SliverList.list(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: ConnectButton(
                  status: vpn.status,
                  size: buttonSize,
                  semanticLabel: vpn.isActive ? l10n.homeDisconnectA11y : l10n.homeConnectA11y,
                  onTap: vpn.status == VpnStatus.disconnecting
                      ? null
                      : () => ref.read(vpnStateProvider.notifier).toggle(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConnectionCaption(state: vpn),
              const _IssueBanner(),
              if (vpn.status == VpnStatus.error && vpn.error == 'admin-required')
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Center(
                    child: SoftButton(
                      label: l10n.restartAsAdmin,
                      icon: LucideIcons.shieldCheck,
                      tone: SoftButtonTone.accent,
                      onPressed: restartAsAdministrator,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),
              if (server != null)
                item(
                  CurrentServerCard(
                    server: server,
                    latency: latency,
                    onTap: () => context.go(AppRoutes.servers),
                  ),
                )
              else if (serversLoading)
                const AppCard(child: Skeleton(height: 46))
              else
                item(const _NoServerCard()),
              const SizedBox(height: AppSpacing.md),
              item(const _SpeedRow()),
              const SizedBox(height: AppSpacing.md),
              item(
                Consumer(
                  builder: (_, ref, _) => SessionTrafficCard(sample: ref.watch(trafficProvider)),
                ),
              ),
              if (subscription != null) ...[
                const SizedBox(height: AppSpacing.md),
                item(SubscriptionCard(subscription: subscription)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SpeedRow extends ConsumerWidget {
  const _SpeedRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final t = ref.watch(trafficProvider);
    final h = ref.watch(speedHistoryProvider);
    return Row(
      children: [
        Expanded(
          child: SpeedCard(
            label: l10n.homeDownload,
            icon: LucideIcons.arrowDown,
            color: c.accentStart,
            bytesPerSecond: t.downSpeed,
            history: h.down,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: SpeedCard(
            label: l10n.homeUpload,
            icon: LucideIcons.arrowUp,
            color: c.accentEnd,
            bytesPerSecond: t.upSpeed,
            history: h.up,
          ),
        ),
      ],
    );
  }
}

class _NoServerCard extends StatelessWidget {
  const _NoServerCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          const IconBadge(icon: LucideIcons.server),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeNoServerTitle, style: theme.textTheme.titleSmall),
                Text(l10n.homeNoServerBody, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SoftButton(
            label: l10n.serversAdd,
            icon: LucideIcons.plus,
            tone: SoftButtonTone.accent,
            height: 40,
            onPressed: () => context.go(AppRoutes.servers),
          ),
        ],
      ),
    );
  }
}

/// Warns when the tunnel is up but traffic can't get through the server.
class _IssueBanner extends ConsumerWidget {
  const _IssueBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issue = ref.watch(connectionIssueProvider);
    final connected = ref.watch(vpnStateProvider.select((s) => s.status == VpnStatus.connected));
    final l10n = context.l10n;
    final c = context.colors;
    final text = switch (issue) {
      ConnectionIssue.serverNotFound => l10n.homeIssueNotFound,
      ConnectionIssue.serverUnreachable => l10n.homeIssueUnreachable,
      null => null,
    };
    return AnimatedSize(
      duration: AppDurations.medium,
      curve: AppCurves.standard,
      child: text == null || !connected
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: AppCard(
                variant: AppCardVariant.elevated,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(LucideIcons.triangleAlert, size: 20, color: c.warning),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              ),
            ),
    );
  }
}
