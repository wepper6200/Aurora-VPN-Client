import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Page background.
///
/// Material 3: the flat `surface` color. Liquid Glass: a vivid aurora of
/// soft color fields for the glass to refract. Glows are painted with radial
/// gradients rather than blur filters, so the background costs a single
/// cheap paint and never re-rasterizes on scroll.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.glowAlignment = 0});

  final Widget child;

  /// Shifts the glows horizontally (-1..1), lets screens vary the mood a bit.
  final double glowAlignment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (c.isMaterial) return ColoredBox(color: c.background, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: c.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AuroraPainter(colors: c, shift: glowAlignment),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.colors, required this.shift});

  final AppColors colors;
  final double shift;

  static const _blue = Color(0xFF3B82F6);
  static const _pink = Color(0xFFEC4899);

  @override
  void paint(Canvas canvas, Size size) {
    final k = colors.glowStrength;
    void glow(Offset center, double radius, Color color, double alpha) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha * k),
            color.withValues(alpha: alpha * k * 0.45),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect);
      canvas.drawCircle(center, radius, paint);
    }

    final w = size.width, h = size.height;
    final r = size.shortestSide * 0.95;
    final dark = colors.isDark;
    glow(Offset(w * (0.12 + 0.1 * shift), h * 0.08), r, colors.accentStart, dark ? 0.5 : 0.4);
    glow(Offset(w * (0.95 - 0.1 * shift), h * 0.34), r * 0.95, colors.accentEnd, dark ? 0.5 : 0.36);
    glow(Offset(w * 0.1, h * 0.82), r * 0.85, _blue, dark ? 0.36 : 0.26);
    glow(Offset(w * 0.92, h * 1.0), r * 0.8, _pink, dark ? 0.26 : 0.2);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.colors != colors || old.shift != shift;
}
