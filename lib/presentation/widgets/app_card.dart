import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';

enum AppCardVariant {
  /// Solid surface with a hairline border and soft shadow.
  solid,

  /// Slightly lighter surface, no shadow — for nested content.
  elevated,

  /// Translucent surface over a backdrop blur.
  glass,
}

/// Rounded surface used for nearly every block of content.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.xl,
    this.variant = AppCardVariant.solid,
    this.onTap,
    this.onLongPress,
    this.gradientBorder = false,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Draws a 1.5px accent-gradient border (e.g. for the active server).
  final bool gradientBorder;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final borderRadius = BorderRadius.circular(radius);
    final fill = switch (variant) {
      AppCardVariant.solid => c.surface,
      AppCardVariant.elevated => c.surfaceElevated,
      AppCardVariant.glass => c.surfaceGlass,
    };
    final showGradient = gradientBorder || selected;

    Widget content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: child),
      ),
    );

    content = AnimatedContainer(
      duration: AppDurations.medium,
      curve: AppCurves.standard,
      decoration: BoxDecoration(
        color: selected ? Color.alphaBlend(c.accentStart.withValues(alpha: 0.07), fill) : fill,
        borderRadius: borderRadius,
        border: showGradient ? null : Border.all(color: c.border),
      ),
      child: ClipRRect(borderRadius: borderRadius, child: content),
    );

    if (variant == AppCardVariant.glass) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: content),
      );
    }

    if (showGradient) {
      content = Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: c.accentGradient,
          borderRadius: BorderRadius.circular(radius + 1.5),
        ),
        child: content,
      );
    }

    final shadow = variant == AppCardVariant.solid
        ? [
            BoxShadow(
              color: c.shadow,
              blurRadius: c.isDark ? 28 : 32,
              spreadRadius: c.isDark ? -6 : -12,
              offset: Offset(0, c.isDark ? 10 : 12),
            ),
          ]
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadow),
      child: content,
    );
  }
}
