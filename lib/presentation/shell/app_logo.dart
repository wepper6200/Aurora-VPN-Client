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
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.c);

  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shader = c.accentGradient.createShader(rect);
    final r = size.width / 2;
    final center = rect.center;

    final ring = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.82),
      -math.pi * 0.35,
      math.pi * 1.7,
      false,
      ring,
    );

    final arc = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(center.dx - r * 0.42, center.dy + r * 0.28)
      ..quadraticBezierTo(
        center.dx,
        center.dy - r * 0.62,
        center.dx + r * 0.42,
        center.dy + r * 0.28,
      );
    canvas.drawPath(path, arc);

    canvas.drawCircle(
      Offset(center.dx, center.dy + r * 0.3),
      size.width * 0.07,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.c != c;
}
