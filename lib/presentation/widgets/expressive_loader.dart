import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Busy indicator for short waits.
///
/// Material 3: the Expressive loading indicator — a shape that morphs
/// through soft burst → cookie → pentagon → clover → sunny while turning,
/// optionally on a round `secondaryContainer` plate. Liquid Glass: a thin
/// circular spinner, which suits the glass look better.
class ExpressiveLoader extends StatefulWidget {
  const ExpressiveLoader({super.key, this.size = 48, this.color, this.contained = true});

  final double size;

  /// Shape color; defaults to `primary`.
  final Color? color;

  /// Draws the round plate behind the shape.
  final bool contained;

  @override
  State<ExpressiveLoader> createState() => _ExpressiveLoaderState();
}

class _ExpressiveLoaderState extends State<ExpressiveLoader> with SingleTickerProviderStateMixin {
  /// One morph step per shape, as in the Material spec (~650 ms each).
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 650 * _shapes.length),
  )..repeat();

  static const _samples = 72;

  /// (lobes, amplitude) of each step.
  static const _shapes = [(6, 0.12), (9, 0.07), (5, 0.1), (4, 0.1), (12, 0.05)];

  static final List<Float64List> _radii = [
    for (final (n, a) in _shapes)
      Float64List.fromList([
        for (var i = 0; i < _samples; i++) 1 + a * math.cos(n * i / _samples * 2 * math.pi),
      ]),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = widget.size;
    if (c.isGlass) {
      return SizedBox.square(
        dimension: size,
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: CircularProgressIndicator(
            strokeWidth: math.max(1.6, size * 0.09),
            color: widget.color ?? c.accentStart,
          ),
        ),
      );
    }
    final s = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _LoaderPainter(
          animation: _c,
          color: widget.color ?? s.primary,
          plate: widget.contained ? s.secondaryContainer : null,
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter({required this.animation, required this.color, this.plate})
    : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final Color? plate;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final half = size.width / 2;
    if (plate != null) canvas.drawCircle(center, half, Paint()..color = plate!);

    const shapes = _ExpressiveLoaderState._shapes;
    const n = _ExpressiveLoaderState._samples;
    final radii = _ExpressiveLoaderState._radii;
    final t = animation.value * shapes.length;
    final i = t.floor() % shapes.length;
    final from = radii[i], to = radii[(i + 1) % shapes.length];
    // Hold each shape briefly, then morph with a springy ease.
    final local = Curves.easeOutBack.transform(((t - t.floor()) * 1.6).clamp(0.0, 1.0));
    final rotation = animation.value * 2 * math.pi * 2 - math.pi / 2;
    final r = half * (plate != null ? 0.62 : 0.92) / 1.12;

    final path = Path();
    for (var k = 0; k < n; k++) {
      final a = k / n * 2 * math.pi + rotation;
      final rr = r * (from[k] + (to[k] - from[k]) * local);
      final p = center + Offset(math.cos(a), math.sin(a)) * rr;
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LoaderPainter old) => old.color != color || old.plate != plate;
}
