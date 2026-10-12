import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../application/servers/servers_controller.dart';
import '../../../../core/l10n.dart';
import '../../../../domain/servers/server_profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/app_card.dart';

/// Round avatar: the flag emoji if the name starts with one, else an initial.
class ServerAvatar extends StatelessWidget {
  const ServerAvatar({super.key, required this.name, this.size = 42, this.active = false});

  final String name;
  final double size;
  final bool active;

  static final _flag = RegExp(r'^\s*([\u{1F1E6}-\u{1F1FF}]{2})', unicode: true);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final flag = _flag.firstMatch(name)?.group(1);
    final letter = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    final onAccent = c.isDark ? const Color(0xFF071613) : Colors.white;
    return AnimatedContainer(
      duration: AppDurations.medium,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? c.accentGradient
            : LinearGradient(
                colors: [
                  c.accentStart.withValues(alpha: c.isDark ? 0.16 : 0.14),
                  c.accentEnd.withValues(alpha: c.isDark ? 0.16 : 0.14),
                ],
              ),
      ),
      child: flag != null
          ? Text(flag, style: TextStyle(fontSize: size * 0.48))
          : Text(
              letter,
              style: Theme.of(context).textTheme.titleMedium!
                  .copyWith(color: active ? onAccent : c.accentStart, fontSize: size * 0.4),
            ),
    );
  }
}

/// "48 ms" pill colored by quality, a spinner while testing.
class LatencyPill extends StatelessWidget {
  const LatencyPill({super.key, required this.result});

  final LatencyResult? result;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = result;
    if (r == null) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.labelMedium!;

    Widget child;
    Color color;
    switch (r.state) {
      case LatencyState.testing:
        color = c.textTertiary;
        child = SizedBox.square(
          dimension: 12,
          child: CircularProgressIndicator(strokeWidth: 1.8, color: c.accentStart),
        );
      case LatencyState.failed:
        color = c.danger;
        child = Text(context.l10n.latencyTimeout, style: style.copyWith(color: color));
      case LatencyState.ok:
        final ms = r.ms!;
        color = ms <= 120
            ? c.success
            : ms <= 300
            ? c.warning
            : c.danger;
        child = Text('$ms ms', style: style.copyWith(color: color));
    }
    return AnimatedContainer(
      duration: AppDurations.medium,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: c.isDark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: AnimatedSwitcher(duration: AppDurations.fast, child: child),
    );
  }
}

/// "VLESS · Reality · gRPC"
String serverSubtitle(ServerProfile s) {
  final parts = <String>[s.protocol.label];
  if (s.security == 'reality') {
    parts.add('Reality');
  } else if (s.security == 'tls') {
    parts.add('TLS');
  }
  if (s.transport != 'tcp' && s.transport != 'udp') {
    parts.add(switch (s.transport) {
      'ws' => 'WS',
      'grpc' => 'gRPC',
      'h2' => 'H2',
      'httpupgrade' => 'HTTPUpgrade',
      'quic' => 'QUIC',
      final t => t,
    });
  }
  return parts.join(' · ');
}

enum ServerMenuAction { edit, copyLink, delete }

class ServerTile extends StatelessWidget {
  const ServerTile({
    super.key,
    required this.server,
    required this.selected,
    required this.latency,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onMenu,
  });

  final ServerProfile server;
  final bool selected;
  final LatencyResult? latency;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final ValueChanged<ServerMenuAction> onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AppCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      radius: AppRadii.lg,
      child: Row(
        children: [
          ServerAvatar(name: server.name, active: selected),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  serverSubtitle(server),
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          LatencyPill(result: latency),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: server.favorite ? l10n.actionUnfavorite : l10n.actionFavorite,
            onPressed: onToggleFavorite,
            style: _compact,
            icon: AnimatedSwitcher(
              duration: AppDurations.medium,
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              // Lucide has no filled glyphs; the Material star reads as "on".
              child: Icon(
                server.favorite ? Icons.star_rounded : LucideIcons.star,
                key: ValueKey(server.favorite),
                size: server.favorite ? 23 : 20,
                color: server.favorite ? c.warning : c.textTertiary,
              ),
            ),
          ),
          PopupMenuButton<ServerMenuAction>(
            icon: Icon(LucideIcons.ellipsisVertical, size: 20, color: c.textTertiary),
            style: _compact,
            onSelected: onMenu,
            itemBuilder: (context) => [
              menuItem(ServerMenuAction.edit, LucideIcons.pencil, l10n.actionEdit),
              menuItem(ServerMenuAction.copyLink, LucideIcons.link, l10n.actionCopyLink),
              menuItem(
                ServerMenuAction.delete,
                LucideIcons.trash2,
                l10n.actionDelete,
                color: c.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Narrow icon buttons so long server names get more room.
final _compact = IconButton.styleFrom(
  minimumSize: const Size(34, 40),
  fixedSize: const Size(34, 40),
  padding: EdgeInsets.zero,
);

PopupMenuItem<T> menuItem<T>(T value, IconData icon, String label, {Color? color}) {
  return PopupMenuItem<T>(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: color == null ? null : TextStyle(color: color)),
      ],
    ),
  );
}
