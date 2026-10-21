import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../application/servers/servers_controller.dart';
import '../../../../application/settings/settings_controller.dart';
import '../../../../core/clock.dart';
import '../../../../core/l10n.dart';
import '../../../../domain/servers/server_profile.dart';
import '../../../../domain/settings/app_settings.dart';
import '../../../../domain/subscriptions/subscription.dart';
import '../../../../domain/vpn/vpn_core.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../../util/formatters.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/decorations.dart';
import '../../../widgets/form_section.dart';
import '../../../widgets/sparkline.dart';
import '../../../widgets/usage_bar.dart';
import '../../servers/widgets/server_widgets.dart';

/// Ticking `HH:MM:SS` since [since].
class SessionTimer extends ConsumerStatefulWidget {
  const SessionTimer({super.key, required this.since, this.style});

  final DateTime since;
  final TextStyle? style;

  @override
  ConsumerState<SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends ConsumerState<SessionTimer> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(nowProvider)().difference(widget.since);
    return Text(Fmt.duration(d.isNegative ? Duration.zero : d), style: widget.style?.tabular);
  }
}

/// Status headline + secondary line under the connect button.
class ConnectionCaption extends StatelessWidget {
  const ConnectionCaption({super.key, required this.state});

  final VpnState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final theme = Theme.of(context);

    final (title, color) = switch (state.status) {
      VpnStatus.disconnected => (l10n.statusDisconnected, c.textPrimary),
      VpnStatus.connecting => (l10n.statusConnecting, c.accentStart),
      VpnStatus.connected => (l10n.statusConnected, c.success),
      VpnStatus.disconnecting => (l10n.statusDisconnecting, c.textSecondary),
      VpnStatus.error => (l10n.statusError, c.danger),
    };
    final subStyle = theme.textTheme.bodyMedium!.copyWith(color: c.textSecondary);
    final Widget sub = switch (state.status) {
      VpnStatus.connected when state.connectedAt != null => SessionTimer(
        since: state.connectedAt!,
        style: theme.textTheme.titleMedium!.copyWith(color: c.textSecondary),
      ),
      VpnStatus.connecting => Text(l10n.homeConnectingHint, style: subStyle),
      VpnStatus.error => Text(
        switch (state.error) {
          'no-server' => l10n.homeErrorNoServer,
          'permission-denied' => l10n.homeErrorPermission,
          'admin-required' => l10n.errAdminRequired,
          'core-missing' => l10n.errCoreMissing,
          final e => e ?? l10n.unknownError,
        },
        style: subStyle.copyWith(color: c.danger),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      _ => Text(l10n.homeTapToConnect, style: subStyle),
    };

    return AnimatedSwitcher(
      duration: AppDurations.medium,
      switchInCurve: AppCurves.standard,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(a),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(state.status),
        children: [
          Text(title, style: theme.textTheme.headlineSmall!.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(height: 24, child: Center(child: sub)),
        ],
      ),
    );
  }
}

class CurrentServerCard extends StatelessWidget {
  const CurrentServerCard({
    super.key,
    required this.server,
    required this.latency,
    required this.onTap,
    this.onPing,
  });

  final ServerProfile server;
  final LatencyResult? latency;
  final VoidCallback onTap;

  /// Measures this server's ping.
  final VoidCallback? onPing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          ServerAvatar(name: server.name, size: 46, active: true),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayServerName(server.name),
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(serverSubtitle(server), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (latency == null && onPing != null)
            IconButton(
              tooltip: l10n.pingCheck,
              onPressed: onPing,
              icon: Icon(LucideIcons.gauge, size: 20, color: c.accentStart),
            )
          else
            LatencyPill(result: latency, onTap: onPing),
          const SizedBox(width: AppSpacing.xs),
          Icon(LucideIcons.chevronRight, size: 20, color: c.textTertiary),
        ],
      ),
    );
  }
}

class SpeedCard extends StatelessWidget {
  const SpeedCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.bytesPerSecond,
    required this.history,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int bytesPerSecond;
  final List<double> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final speed = Fmt.speedParts(bytesPerSecond, locale);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, size: 28, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: speed.value, style: theme.textTheme.headlineSmall!.tabular),
                TextSpan(
                  text: ' ${speed.unit}',
                  style: theme.textTheme.labelMedium!.copyWith(color: c.textTertiary),
                ),
              ],
            ),
            maxLines: 1,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: Sparkline(values: history, color: color),
          ),
        ],
      ),
    );
  }
}

/// Windows: system proxy or TUN, switchable right from the home screen.
class TunnelModeCard extends ConsumerWidget {
  const TunnelModeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final mode = ref.watch(settingsProvider.select((s) => s.windowsMode));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormSegmented<WindowsTunnelMode>(
            label: l10n.settingsWindowsMode,
            value: mode,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).update((s) => s.copyWith(windowsMode: v)),
            options: {
              WindowsTunnelMode.systemProxy: l10n.modeProxy,
              WindowsTunnelMode.tun: l10n.modeTun,
            },
          ),
          AnimatedSize(
            duration: AppDurations.medium,
            child: mode == WindowsTunnelMode.tun
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(LucideIcons.shieldAlert, size: 16, color: c.warning),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.modeTunHint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class SessionTrafficCard extends StatelessWidget {
  const SessionTrafficCard({super.key, required this.sample});

  final TrafficSample sample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final value = theme.textTheme.titleSmall!.tabular;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          IconBadge(icon: LucideIcons.activity, size: 32, color: c.info),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(l10n.homeSessionTraffic, style: theme.textTheme.labelLarge)),
          Icon(LucideIcons.arrowDown, size: 14, color: c.accentStart),
          const SizedBox(width: 2),
          Text(Fmt.bytes(sample.downTotal, locale), style: value),
          const SizedBox(width: AppSpacing.md),
          Icon(LucideIcons.arrowUp, size: 14, color: c.accentEnd),
          const SizedBox(width: 2),
          Text(Fmt.bytes(sample.upTotal, locale), style: value),
        ],
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key, required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final usage = subscription.usage;
    final expire = usage?.expire;
    final days = expire == null ? null : Fmt.daysUntil(expire);

    final String trafficLine;
    if (usage == null || usage.unlimited) {
      trafficLine = l10n.subUnlimited;
    } else {
      trafficLine = l10n.subUsedOf(Fmt.bytes(usage.used, locale), Fmt.bytes(usage.total, locale));
    }

    final expiryColor = days == null
        ? c.textSecondary
        : days < 0
        ? c.danger
        : days <= 5
        ? c.warning
        : c.success;
    final expiryText = days == null
        ? l10n.subNoExpiry
        : days < 0
        ? l10n.subExpired
        : l10n.subExpiresInDays(days);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: LucideIcons.layers, size: 32, color: c.accentEnd),
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
                    Text(trafficLine, style: theme.textTheme.bodySmall!.tabular),
                  ],
                ),
              ),
              StatusPill(label: expiryText, color: expiryColor, dot: false),
            ],
          ),
          if (usage?.usedFraction != null) ...[
            const SizedBox(height: AppSpacing.md),
            UsageBar(fraction: usage!.usedFraction!),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.subLeft(Fmt.bytes(usage.remaining!, locale)),
              style: theme.textTheme.labelSmall!.copyWith(color: c.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
