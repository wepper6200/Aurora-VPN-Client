import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../domain/settings/app_settings.dart';
import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// Two side-by-side cards with live miniatures of each design style.
/// Used on the first onboarding page and in Settings → Appearance.
class DesignStylePicker extends StatelessWidget {
  const DesignStylePicker({super.key, required this.value, required this.onChanged});

  final DesignStyle value;
  final ValueChanged<DesignStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StyleCard(
            title: l10n.designMaterial,
            subtitle: l10n.designMaterialSub,
            selected: value == DesignStyle.material,
            onTap: () => onChanged(DesignStyle.material),
            preview: const _MaterialPreview(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StyleCard(
            title: l10n.designGlass,
            subtitle: l10n.designGlassSub,
            selected: value == DesignStyle.glass,
            onTap: () => onChanged(DesignStyle.glass),
            preview: const _GlassPreview(),
          ),
        ),
      ],
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.preview,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        semanticLabel: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: AppDurations.medium,
              curve: AppCurves.standard,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(
                  color: selected ? accent : c.border,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: AspectRatio(aspectRatio: 0.82, child: preview),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: AppDurations.medium,
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        child: Icon(
                          LucideIcons.check600,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Miniature of the Material 3 home screen with a live wavy loader.
class _MaterialPreview extends StatefulWidget {
  const _MaterialPreview();

  @override
  State<_MaterialPreview> createState() => _MaterialPreviewState();
}

class _MaterialPreviewState extends State<_MaterialPreview> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A few loops are enough to show the motion; it then rests instead of
    // burning frames while the user reads.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.repeat(count: 4);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0E1513),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  size: const Size.square(96),
                  painter: _MiniM3Painter(_c.value),
                  child: const SizedBox.square(
                    dimension: 96,
                    child: Icon(LucideIcons.power600, size: 22, color: Color(0xFF8FF8E1)),
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 30,
            color: const Color(0xFF1B211F),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 28,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334B46),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3F4946),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniM3Painter extends CustomPainter {
  _MiniM3Painter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.width;
    final rot = t * 2 * math.pi;

    final shape = Path();
    const n = 90;
    for (var i = 0; i <= n; i++) {
      final a = i / n * 2 * math.pi;
      final r = unit * 0.3 * (1 + 0.07 * math.cos(9 * a));
      final p = center + Offset(math.cos(a + rot * 0.1), math.sin(a + rot * 0.1)) * r;
      i == 0 ? shape.moveTo(p.dx, p.dy) : shape.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(shape, Paint()..color = const Color(0xFF005046));

    final sweep = (0.25 + 0.4 * (0.5 - 0.5 * math.cos(rot))) * 2 * math.pi;
    final wave = Path();
    const steps = 80;
    for (var i = 0; i <= steps; i++) {
      final a = rot * 1.5 + sweep * i / steps;
      final r = unit * 0.45 + 1.6 * math.sin(14 * a + rot * 3);
      final p = center + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? wave.moveTo(p.dx, p.dy) : wave.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6FDBC6),
    );
  }

  @override
  bool shouldRepaint(_MiniM3Painter old) => old.t != t;
}

/// Miniature of the Liquid Glass home screen.
class _GlassPreview extends StatelessWidget {
  const _GlassPreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.8, -0.8),
              radius: 1.1,
              colors: [Color(0xCC2DE2C5), Color(0x002DE2C5)],
            ),
            color: Color(0xFF05060C),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, 0.1),
              radius: 1,
              colors: [Color(0xCC8B5CF6), Color(0x008B5CF6)],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.6, 1),
              radius: 0.9,
              colors: [Color(0x993B82F6), Color(0x003B82F6)],
            ),
          ),
        ),
        Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.4),
                      colors: [
                        const Color(0xFF2DE2C5).withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2DE2C5).withValues(alpha: 0.5),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.power600, size: 24, color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: i == 0 ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? const Color(0xFF7FF3DE)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
