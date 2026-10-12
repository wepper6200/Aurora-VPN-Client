import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Page background: a vertical gradient with two soft accent glows.
///
/// Glows are painted with radial gradients rather than blur filters, so the
/// background costs a single cheap paint and never re-rasterizes on scroll.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.glowAlignment = 0});

  final Widget child;

  /// Shifts the glows horizontally (-1..1), lets screens vary the mood a bit.
  final double glowAlignment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: c.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _GlowPainter(colors: c, shift: glowAlignment),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.colors, required this.shift});

  final AppColors colors;
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset center, double radius, Color color, double alpha) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha * colors.glowStrength),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }

    final r = size.shortestSide * 0.9;
    glow(Offset(size.width * (0.15 + 0.1 * shift), -r * 0.15), r, colors.accentStart, 0.16);
    glow(
      Offset(size.width * (0.95 - 0.1 * shift), size.height * 0.28),
      r * 0.9,
      colors.accentEnd,
      0.14,
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.colors != colors || old.shift != shift;
}
