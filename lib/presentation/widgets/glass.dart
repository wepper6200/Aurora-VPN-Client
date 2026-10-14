import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Liquid Glass panel: translucent fill, a specular rim and a soft top sheen.
///
/// The backdrop blur is opt-in. The app background is built from smooth
/// gradients, so in-flow cards already read as glass without it; only
/// floating chrome (tab bar, connect orb) pays for a real blur, which keeps
/// long server lists smooth on phones.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.blur = false,
    this.tint,
    this.accent,
    this.padding,
    this.shadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Blurs and saturates whatever is behind the panel.
  final bool blur;

  /// Fill color; defaults to [AppColors.surfaceGlass].
  final Color? tint;

  /// Colors the rim (e.g. the selected server).
  final Color? accent;
  final EdgeInsetsGeometry? padding;
  final bool shadow;

  /// Blur + saturation boost, the "vibrancy" of real glass.
  static final ImageFilter backdrop = ImageFilter.compose(
    outer: const ColorFilter.matrix(_saturate),
    inner: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
  );

  static const List<double> _saturate = [
    1.45, -0.38, -0.07, 0, 0, //
    -0.12, 1.19, -0.07, 0, 0, //
    -0.12, -0.38, 1.5, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget content = CustomPaint(
      painter: GlassFillPainter(
        radius: borderRadius,
        fill: tint ?? c.surfaceGlass,
        dark: c.isDark,
      ),
      foregroundPainter: GlassRimPainter(radius: borderRadius, dark: c.isDark, accent: accent),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    if (blur) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(filter: backdrop, child: content),
      );
    }
    if (!shadow) return content;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: c.shadow.a * 0.7),
            blurRadius: 30,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: content,
    );
  }
}

/// Translucent body with a light sheen fading down from the top edge.
class GlassFillPainter extends CustomPainter {
  const GlassFillPainter({required this.radius, required this.fill, required this.dark});

  final BorderRadius radius;
  final Color fill;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect);
    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.11 : 0.45),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.55],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(GlassFillPainter old) =>
      old.fill != fill || old.radius != radius || old.dark != dark;
}

/// Specular rim: bright on the top-left and bottom-right, nearly invisible
/// on the sides — light caught by the edges of a lens.
class GlassRimPainter extends CustomPainter {
  const GlassRimPainter({required this.radius, required this.dark, this.accent});

  final BorderRadius radius;
  final bool dark;
  final Color? accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.6);
    final rrect = radius.toRRect(rect);
    final a = accent;
    final colors = a != null
        ? [
            a.withValues(alpha: 0.95),
            a.withValues(alpha: 0.3),
            a.withValues(alpha: 0.15),
            a.withValues(alpha: 0.7),
          ]
        : dark
        ? [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.28),
          ]
        : [
            Colors.white,
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.9),
          ];
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = a != null ? 1.6 : 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: const [0, 0.35, 0.65, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(GlassRimPainter old) =>
      old.radius != radius || old.dark != dark || old.accent != accent;
}
