import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Vector logo mark: a gradient ring with an aurora arc inside.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LogoPainter(context.colors)),
    );
  }

  /// Paints the mark into [rect]. Shared with `tool/icons`, which renders the
  /// launcher, window and tray icons from this exact geometry. [color]
  /// replaces the gradient (monochrome icons).
  static void paintMark(Canvas canvas, Rect rect, {Gradient? gradient, Color? color}) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.12
      ..strokeCap = StrokeCap.round;
    if (color != null) {
      paint.color = color;
    } else {
      paint.shader = (gradient ?? AppColors.dark.accentGradient).createShader(rect);
    }
    final r = rect.width / 2;
    final center = rect.center;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.82),
      -math.pi * 0.35,
      math.pi * 1.7,
      false,
      paint,
    );

    final path = Path()
      ..moveTo(center.dx - r * 0.42, center.dy + r * 0.28)
      ..quadraticBezierTo(
        center.dx,
        center.dy - r * 0.62,
        center.dx + r * 0.42,
        center.dy + r * 0.28,
      );
    canvas.drawPath(path, paint);

    canvas.drawCircle(
      Offset(center.dx, center.dy + r * 0.3),
      rect.width * 0.07,
      paint..style = PaintingStyle.fill,
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.c);

  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) =>
      AppLogo.paintMark(canvas, Offset.zero & size, gradient: c.accentGradient);

  @override
  bool shouldRepaint(_LogoPainter old) => old.c != c;
}
