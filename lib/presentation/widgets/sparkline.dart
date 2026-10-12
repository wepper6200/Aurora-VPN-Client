import 'package:flutter/material.dart';

/// Smooth live line chart. When a sample is appended the line glides left by
/// one step instead of jumping, so a 1 Hz feed still looks fluid at 60 fps.
class Sparkline extends StatefulWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.capacity = 40,
    this.strokeWidth = 2,
  });

  final List<double> values;
  final Color color;

  /// Number of samples that span the full width.
  final int capacity;
  final double strokeWidth;

  @override
  State<Sparkline> createState() => _SparklineState();
}

class _SparklineState extends State<Sparkline> with SingleTickerProviderStateMixin {
  late final AnimationController _shift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: 1,
  );

  @override
  void didUpdateWidget(Sparkline old) {
    super.didUpdateWidget(old);
    if (widget.values.isNotEmpty && !identical(old.values, widget.values)) {
      _shift.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _shift,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _SparklinePainter(
              values: widget.values,
              color: widget.color,
              capacity: widget.capacity,
              strokeWidth: widget.strokeWidth,
              shift: 1 - Curves.easeOutCubic.transform(_shift.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.capacity,
    required this.strokeWidth,
    required this.shift,
  });

  final List<double> values;
  final Color color;
  final int capacity;
  final double strokeWidth;

  /// 0..1 fraction of a step the line is still offset to the right.
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height - strokeWidth;
    if (values.length < 2) {
      final y = size.height - strokeWidth / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..strokeWidth = 1.5,
      );
      return;
    }

    var maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV <= 0) maxV = 1;
    final step = size.width / (capacity - 1);
    final n = values.length;
    final pts = [
      for (var i = 0; i < n; i++)
        Offset(
          size.width - (n - 1 - i) * step + shift * step,
          strokeWidth / 2 + h - (values[i] / maxV) * h * 0.92,
        ),
    ];

    // Catmull-Rom → cubic Bézier for a smooth curve through every sample.
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < n - 1; i++) {
      final p0 = pts[i == 0 ? 0 : i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i + 2 < n ? i + 2 : n - 1];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      line.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    final fill = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    final rect = Offset.zero & size;
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(rect),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.shift != shift || old.color != color;
}
