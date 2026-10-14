import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'expressive_loader.dart';
import 'glass.dart';
import 'pressable.dart';

/// Primary call-to-action.
///
/// Material 3: a filled pill in `primary` that squeezes its corners while
/// pressed. Liquid Glass: an accent-tinted glass capsule with a soft glow.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;
    final fg = c.isGlass ? Colors.white : scheme.onPrimary;
    final textStyle = Theme.of(context).textTheme.labelLarge!.copyWith(color: fg, fontSize: 15);

    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          ExpressiveLoader(size: 20, color: fg, contained: false)
        else if (icon != null)
          Icon(icon, size: 20, color: fg),
        if (loading || icon != null) const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, style: textStyle, overflow: TextOverflow.ellipsis)),
      ],
    );

    final Widget body;
    if (c.isGlass) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: [
            BoxShadow(
              color: c.accentStart.withValues(alpha: 0.35 * c.glowStrength),
              blurRadius: 26,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          shadow: false,
          tint: Color.alphaBlend(
            c.accentStart.withValues(alpha: c.isDark ? 0.42 : 0.75),
            c.accentEnd.withValues(alpha: c.isDark ? 0.2 : 0.4),
          ),
          child: SizedBox(
            height: height,
            width: expand ? double.infinity : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: row,
            ),
          ),
        ),
      );
    } else {
      body = _SqueezeShape(
        color: scheme.primary,
        height: height,
        expand: expand,
        child: row,
      );
    }

    return Pressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      scale: c.isGlass ? 0.96 : 0.98,
      child: AnimatedOpacity(
        duration: AppDurations.fast,
        opacity: enabled || loading ? 1 : 0.45,
        child: body,
      ),
    );
  }
}

/// Material 3 Expressive button shape: a full pill at rest that morphs to
/// a rounded rectangle while pressed.
class _SqueezeShape extends StatefulWidget {
  const _SqueezeShape({
    required this.color,
    required this.height,
    required this.expand,
    required this.child,
  });

  final Color color;
  final double height;
  final bool expand;
  final Widget child;

  @override
  State<_SqueezeShape> createState() => _SqueezeShapeState();
}

class _SqueezeShapeState extends State<_SqueezeShape> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        height: widget.height,
        width: widget.expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(_down ? AppRadii.sm : widget.height / 2),
        ),
        child: widget.child,
      ),
    );
  }
}

enum SoftButtonTone { neutral, accent, danger }

/// Secondary button.
///
/// Material 3: a tonal pill (`secondaryContainer`, `primaryContainer` or
/// `errorContainer`). Liquid Glass: a lightly tinted glass capsule.
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = SoftButtonTone.neutral,
    this.expand = false,
    this.height = 48,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SoftButtonTone tone;
  final bool expand;
  final double height;

  /// Replaces the icon with a spinner and ignores taps.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = c.isGlass
        ? switch (tone) {
            SoftButtonTone.neutral => (c.surfaceGlass, c.textPrimary),
            SoftButtonTone.accent => (c.accentStart.withValues(alpha: 0.2), c.accentStart),
            SoftButtonTone.danger => (c.danger.withValues(alpha: 0.18), c.danger),
          }
        : switch (tone) {
            SoftButtonTone.neutral => (s.secondaryContainer, s.onSecondaryContainer),
            SoftButtonTone.accent => (s.primaryContainer, s.onPrimaryContainer),
            SoftButtonTone.danger => (s.errorContainer, s.onErrorContainer),
          };
    final style = Theme.of(context).textTheme.labelLarge!.copyWith(color: fg);
    final content = SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              ExpressiveLoader(size: 20, color: fg, contained: false),
              const SizedBox(width: AppSpacing.sm),
            ] else if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(child: Text(label, style: style, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );

    return Pressable(
      onTap: loading ? null : onPressed,
      semanticLabel: label,
      child: AnimatedOpacity(
        duration: AppDurations.fast,
        opacity: onPressed != null || loading ? 1 : 0.45,
        child: c.isGlass
            ? GlassSurface(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                tint: bg,
                shadow: false,
                child: content,
              )
            : AnimatedContainer(
                duration: AppDurations.medium,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: content,
              ),
      ),
    );
  }
}

/// Round icon button used in headers and toolbars.
///
/// Material 3: a tonal circle. Liquid Glass: a small glass bubble.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.filled = true,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Theme.of(context).colorScheme;
    final iconColor = color ?? (c.isGlass ? c.textPrimary : s.onSurfaceVariant);
    final glyph = Icon(icon, size: size * 0.48, color: iconColor);
    final Widget face;
    if (!filled) {
      face = SizedBox.square(dimension: size, child: glyph);
    } else if (c.isGlass) {
      face = GlassSurface(
        borderRadius: BorderRadius.circular(size / 2),
        shadow: false,
        child: SizedBox.square(dimension: size, child: glyph),
      );
    } else {
      face = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: s.surfaceContainerHigh, shape: BoxShape.circle),
        child: glyph,
      );
    }
    Widget button = Pressable(
      onTap: onPressed,
      scale: 0.9,
      semanticLabel: tooltip,
      child: AnimatedOpacity(
        duration: AppDurations.fast,
        opacity: onPressed != null ? 1 : 0.5,
        child: face,
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}
