import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// Primary call-to-action filled with the accent gradient.
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
    final enabled = onPressed != null && !loading;
    final fg = c.isDark ? const Color(0xFF071613) : Colors.white;
    final textStyle = Theme.of(context).textTheme.labelLarge!.copyWith(color: fg);

    return Pressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      child: AnimatedOpacity(
        duration: AppDurations.fast,
        opacity: enabled || loading ? 1 : 0.45,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          decoration: BoxDecoration(
            gradient: c.accentGradient,
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: [
              BoxShadow(
                color: c.accentEnd.withValues(alpha: 0.35 * c.glowStrength),
                blurRadius: 24,
                spreadRadius: -8,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
                )
              else if (icon != null)
                Icon(icon, size: 20, color: fg),
              if (loading || icon != null) const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(label, style: textStyle, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum SoftButtonTone { neutral, accent, danger }

/// Secondary button with a tinted, low-contrast fill.
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = SoftButtonTone.neutral,
    this.expand = false,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SoftButtonTone tone;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (tone) {
      SoftButtonTone.neutral => (c.surfaceElevated, c.textPrimary),
      SoftButtonTone.accent => (c.accentStart.withValues(alpha: 0.14), c.accentStart),
      SoftButtonTone.danger => (c.danger.withValues(alpha: 0.12), c.danger),
    };
    final style = Theme.of(context).textTheme.labelLarge!.copyWith(color: fg);

    return Pressable(
      onTap: onPressed,
      semanticLabel: label,
      child: AnimatedOpacity(
        duration: AppDurations.fast,
        opacity: onPressed != null ? 1 : 0.45,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: tone == SoftButtonTone.neutral ? Border.all(color: c.border) : null,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(label, style: style, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square icon button with a soft background, used in headers and toolbars.
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
    Widget button = Pressable(
      onTap: onPressed,
      scale: 0.92,
      semanticLabel: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? c.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.sm + 2),
          border: filled ? Border.all(color: c.border) : null,
        ),
        child: Icon(icon, size: size * 0.46, color: color ?? c.textPrimary),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}
