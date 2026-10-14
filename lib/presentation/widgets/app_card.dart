import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'glass.dart';

enum AppCardVariant {
  /// Default content block.
  solid,

  /// One step higher — for nested or emphasized content.
  elevated,

  /// Translucent surface over a real backdrop blur (Liquid Glass only;
  /// Material 3 renders it as [elevated]).
  glass,
}

/// Rounded surface used for nearly every block of content.
///
/// Material 3: a tonal `surfaceContainer` fill, no border or shadow, and a
/// `secondaryContainer` fill when selected. Liquid Glass: a [GlassSurface]
/// whose rim lights up in the accent color when selected.
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

  /// Accent outline (e.g. for the active server).
  final bool gradientBorder;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final borderRadius = BorderRadius.circular(radius);
    final ink = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (c.isGlass) {
      final highlighted = selected || gradientBorder;
      return AnimatedContainer(
        duration: AppDurations.medium,
        curve: AppCurves.standard,
        decoration: BoxDecoration(borderRadius: borderRadius),
        child: GlassSurface(
          borderRadius: borderRadius,
          blur: variant == AppCardVariant.glass,
          shadow: variant != AppCardVariant.elevated,
          tint: selected
              ? Color.alphaBlend(c.accentStart.withValues(alpha: 0.12), c.surfaceGlass)
              : variant == AppCardVariant.elevated
              ? c.surfaceGlass.withValues(alpha: c.surfaceGlass.a * 1.5)
              : null,
          accent: highlighted ? c.accentStart : null,
          child: ClipRRect(borderRadius: borderRadius, child: ink),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final fill = selected
        ? scheme.secondaryContainer
        : switch (variant) {
            AppCardVariant.solid => scheme.surfaceContainer,
            AppCardVariant.elevated || AppCardVariant.glass => scheme.surfaceContainerHigh,
          };
    return AnimatedContainer(
      duration: AppDurations.medium,
      curve: AppCurves.standard,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        border: gradientBorder ? Border.all(color: scheme.primary, width: 1.5) : null,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: ink),
    );
  }
}
