import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../application/servers/servers_controller.dart';
import '../../../../core/l10n.dart';
import '../../../../domain/servers/server_profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/expressive_loader.dart';

final _leadingFlag = RegExp(r'^\s*([\u{1F1E6}-\u{1F1FF}]{2})\s*', unicode: true);

/// ISO country code of a leading flag emoji ("🇪🇪 EST1" → "EE"), if any.
String? flagCountryCode(String name) {
  final flag = _leadingFlag.firstMatch(name)?.group(1);
  if (flag == null) return null;
  return String.fromCharCodes(flag.runes.map((r) => r - 0x1F1E6 + 0x41));
}

/// The name without its leading flag: the avatar already shows it, and
/// Windows has no flag emoji (it would print the letters "EE").
String displayServerName(String name) {
  final rest = name.replaceFirst(_leadingFlag, '').trim();
  return rest.isEmpty ? name.trim() : rest;
}

/// Round avatar: the country flag (drawn as an image, so it also works on
/// Windows) if the name starts with a flag emoji, else an initial.
class ServerAvatar extends StatelessWidget {
  const ServerAvatar({super.key, required this.name, this.size = 42, this.active = false});

  final String name;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Theme.of(context).colorScheme;
    final code = flagCountryCode(name);
    final flag = code != null && FlagCode.fromCountryCode(code) != null ? code : null;
    final shown = displayServerName(name);
    final letter = shown.isEmpty ? '?' : shown.characters.first.toUpperCase();
    final Color fg;
    final BoxDecoration deco;
    if (c.isMaterial) {
      fg = active ? s.onPrimary : s.onSecondaryContainer;
      deco = BoxDecoration(
        shape: BoxShape.circle,
        color: active ? s.primary : s.secondaryContainer,
      );
    } else {
      fg = active ? c.onAccent : c.accentStart;
      deco = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: active ? 0.4 : 0.12)),
        gradient: active
            ? c.accentGradient
            : LinearGradient(
                colors: [
                  c.accentStart.withValues(alpha: c.isDark ? 0.2 : 0.16),
                  c.accentEnd.withValues(alpha: c.isDark ? 0.2 : 0.16),
                ],
              ),
      );
    }
    // A flag fills the circle; the colored ring around it marks the active server.
    final ring = active ? 2.5 : 1.0;
    return AnimatedContainer(
      duration: AppDurations.medium,
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: flag != null ? EdgeInsets.all(ring) : null,
      decoration: deco,
      child: flag != null
          ? CountryFlag.fromCountryCode(
              flag,
              theme: ImageTheme(
                shape: const Circle(),
                width: size - ring * 2,
                height: size - ring * 2,
              ),
            )
          : Text(
              letter,
              style: Theme.of(context).textTheme.titleMedium!
                  .copyWith(color: fg, fontSize: size * 0.4),
            ),
    );
  }
}

/// "48 ms" pill colored by quality, with signal bars so the quality doesn't
/// rely on color alone; a spinner while testing.
class LatencyPill extends StatelessWidget {
  const LatencyPill({super.key, required this.result, this.onTap});

  final LatencyResult? result;

  /// Re-runs the test when set.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = result;
    if (r == null) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700);

    Widget child;
    Color color;
    switch (r.state) {
      case LatencyState.testing:
        color = c.textTertiary;
        child = ExpressiveLoader(
          key: const ValueKey('testing'),
          size: 16,
          color: c.accentStart,
          contained: false,
        );
      case LatencyState.failed:
        color = c.danger;
        child = Row(
          key: const ValueKey('failed'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_cellular_connected_no_internet_0_bar_rounded, size: 14, color: color),
            const SizedBox(width: 4),
            Text(context.l10n.latencyTimeout, style: style.copyWith(color: color)),
          ],
        );
      case LatencyState.ok:
        final ms = r.ms!;
        final (col, bars) = ms <= 120
            ? (c.success, Icons.signal_cellular_alt_rounded)
            : ms <= 300
            ? (c.warning, Icons.signal_cellular_alt_2_bar_rounded)
            : (c.danger, Icons.signal_cellular_alt_1_bar_rounded);
        color = col;
        child = Row(
          key: ValueKey(ms),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(bars, size: 14, color: color),
            const SizedBox(width: 4),
            Text('$ms ms', style: style.copyWith(color: color)),
          ],
        );
    }
    final pill = AnimatedContainer(
      duration: AppDurations.medium,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: c.isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: AnimatedSwitcher(
        duration: AppDurations.medium,
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, a) => ScaleTransition(
          scale: Tween(begin: 0.6, end: 1.0).animate(a),
          child: FadeTransition(opacity: a, child: child),
        ),
        child: child,
      ),
    );
    if (onTap == null || r.state == LatencyState.testing) return pill;
    return Tooltip(
      message: context.l10n.pingCheck,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: pill,
      ),
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
  // VLESS / VMess / Trojan always name their transport, TCP included.
  final v2ray = const {
    ProxyProtocol.vless,
    ProxyProtocol.vmess,
    ProxyProtocol.trojan,
  }.contains(s.protocol);
  if (v2ray || (s.transport != 'tcp' && s.transport != 'udp')) {
    parts.add(switch (s.transport) {
      'tcp' => s.outbound.transport.httpObfs ? 'TCP (HTTP)' : 'TCP',
      'ws' => 'WS',
      'grpc' => 'gRPC',
      'h2' => 'H2',
      'httpupgrade' => 'HTTPUpgrade',
      'xhttp' => 'XHTTP',
      'quic' => 'QUIC',
      final t => t.toUpperCase(),
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
    this.onPing,
  });

  final ServerProfile server;
  final bool selected;
  final LatencyResult? latency;
  final VoidCallback onTap;

  /// Re-tests just this server (tap on its latency pill).
  final VoidCallback? onPing;
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
                  displayServerName(server.name),
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
          LatencyPill(result: latency, onTap: onPing),
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
