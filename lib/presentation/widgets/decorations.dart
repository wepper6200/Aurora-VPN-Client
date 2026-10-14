import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';

/// Paints [child] (usually an [Icon] or [Text]) with the accent gradient.
class GradientMask extends StatelessWidget {
  const GradientMask({super.key, required this.child, this.gradient});

  final Widget child;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final g = gradient ?? context.colors.accentGradient;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => g.createShader(Offset.zero & bounds.size),
      child: child,
    );
  }
}

/// Rounded square with a tinted background holding an icon.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 40,
    this.gradient = false,
  });

  final IconData icon;
  final Color? color;
  final double size;

  /// Fill with the accent gradient instead of a tint.
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = color ?? c.accentStart;
    if (c.isMaterial) {
      // Tonal circle; the default (no color) uses the secondary container.
      final s = Theme.of(context).colorScheme;
      final (bg, fg) = gradient
          ? (s.primary, s.onPrimary)
          : color == null
          ? (s.secondaryContainer, s.onSecondaryContainer)
          : (tint.withValues(alpha: c.isDark ? 0.18 : 0.14), tint);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.5, color: fg),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gradient ? null : tint.withValues(alpha: c.isDark ? 0.18 : 0.14),
        gradient: gradient ? c.accentGradient : null,
        borderRadius: BorderRadius.circular(size * 0.36),
        border: gradient ? null : Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, size: size * 0.5, color: gradient ? c.onAccent : tint),
    );
  }
}

/// Small rounded label with an optional leading status dot.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.dot = true,
    this.pulse = false,
    this.icon,
  });

  final String label;
  final Color color;
  final bool dot;

  /// Animates the dot (e.g. while connecting).
  final bool pulse;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(color: color);
    return AnimatedContainer(
      duration: AppDurations.medium,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: c.isDark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ] else if (dot) ...[
            _Dot(color: color, pulse: pulse),
            const SizedBox(width: 6),
          ],
          Text(label, style: style),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulse});

  final Color color;
  final bool pulse;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (old.pulse != widget.pulse) _sync();
  }

  void _sync() {
    if (widget.pulse) {
      _c.repeat(reverse: true);
    } else {
      _c
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Caption above a group of cards: a sentence-case `primary` label in
/// Material 3, a spaced uppercase label in Liquid Glass.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding});

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xxl, AppSpacing.xs, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: c.isGlass
                ? Text(
                    title.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium!
                        .copyWith(color: c.textTertiary, letterSpacing: 0.8),
                  )
                : Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall!
                        .copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
