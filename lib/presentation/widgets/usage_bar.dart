import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';

/// Thin rounded progress bar filled with the accent gradient; turns warning /
/// danger as it approaches the limit.
class UsageBar extends StatelessWidget {
  const UsageBar({super.key, required this.fraction, this.height = 6});

  /// 0..1
  final double fraction;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final gradient = fraction >= 0.9
        ? LinearGradient(colors: [c.warning, c.danger])
        : fraction >= 0.75
        ? LinearGradient(colors: [c.accentStart, c.warning])
        : c.accentGradient;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        height: height,
        color: c.textPrimary.withValues(alpha: c.isDark ? 0.08 : 0.06),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction.clamp(0, 1)),
          duration: AppDurations.slow,
          curve: AppCurves.standard,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
