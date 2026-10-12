import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';

/// Friendly placeholder for screens and lists without content.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      c.accentStart.withValues(alpha: 0.22 * c.glowStrength + 0.06),
                      c.accentEnd.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(color: c.border),
                ),
                child: Icon(icon, size: 38, color: c.accentStart),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(message!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
              if (action != null) ...[const SizedBox(height: AppSpacing.xxl), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmering placeholder block shown while content loads.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = AppRadii.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = c.surfaceElevated;
    final highlight = Color.alphaBlend(
      (c.isDark ? Colors.white : c.accentStart).withValues(alpha: 0.07),
      base,
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 3 - 1; // sweep from -1 to 2
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: [base, highlight, base],
              stops: [(t - 0.4).clamp(0, 1), t.clamp(0, 1), (t + 0.4).clamp(0, 1)],
            ),
          ),
        );
      },
    );
  }
}

/// Fades and slides its child in, delayed by [index] — for staggered lists.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({super.key, required this.index, required this.child, this.offset = 16});

  final int index;
  final Widget child;
  final double offset;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    // The delay is baked into the curve (no timers to cancel), and capped so
    // long lists don't keep the user waiting.
    final delay = AppDurations.stagger * widget.index.clamp(0, 10);
    final total = delay + AppDurations.slow;
    _c = AnimationController(vsync: this, duration: total)..forward();
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1, curve: AppCurves.standard),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - _t.value)), child: child),
      ),
      child: widget.child,
    );
  }
}
