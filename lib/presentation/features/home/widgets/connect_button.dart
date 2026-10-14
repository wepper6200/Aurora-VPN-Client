import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../domain/vpn/vpn_core.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/glass.dart';
import '../../../widgets/pressable.dart';
import 'm3_connect_button.dart';

/// The big connect/disconnect button; its look follows the design style.
class ConnectButton extends StatelessWidget {
  const ConnectButton({
    super.key,
    required this.status,
    required this.onTap,
    this.size = 232,
    this.semanticLabel,
  });

  final VpnStatus status;
  final VoidCallback? onTap;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return context.colors.isGlass
        ? _GlassConnectButton(
            status: status,
            onTap: onTap,
            size: size,
            semanticLabel: semanticLabel,
          )
        : M3ConnectButton(status: status, onTap: onTap, size: size, semanticLabel: semanticLabel);
  }
}

/// Visual parameters of one connection state; lerped during transitions.
class _Palette {
  const _Palette({
    required this.tint,
    required this.icon,
    required this.glow,
    required this.glowAmount,
  });

  /// Color refracted inside the orb.
  final Color tint;
  final Color icon;
  final Color glow;
  final double glowAmount;

  static _Palette of(VpnStatus s, AppColors c) {
    switch (s) {
      case VpnStatus.disconnected:
        return _Palette(
          tint: Colors.white.withValues(alpha: c.isDark ? 0.05 : 0.3),
          icon: c.textSecondary,
          glow: c.accentEnd,
          glowAmount: 0.12,
        );
      case VpnStatus.connecting:
      case VpnStatus.disconnecting:
        return _Palette(
          tint: c.accentEnd.withValues(alpha: 0.3),
          icon: c.isDark ? Colors.white : c.accentEnd,
          glow: c.accentEnd,
          glowAmount: 0.45,
        );
      case VpnStatus.connected:
        return _Palette(
          tint: c.accentStart.withValues(alpha: c.isDark ? 0.48 : 0.55),
          icon: c.isDark ? const Color(0xFFE9FFFB) : Colors.white,
          glow: c.accentStart,
          glowAmount: 1,
        );
      case VpnStatus.error:
        return _Palette(
          tint: c.danger.withValues(alpha: 0.45),
          icon: Colors.white,
          glow: c.danger,
          glowAmount: 0.6,
        );
    }
  }

  static _Palette lerp(_Palette a, _Palette b, double t) => _Palette(
    tint: Color.lerp(a.tint, b.tint, t)!,
    icon: Color.lerp(a.icon, b.icon, t)!,
    glow: Color.lerp(a.glow, b.glow, t)!,
    glowAmount: a.glowAmount + (b.glowAmount - a.glowAmount) * t,
  );
}

/// Liquid Glass connect button: a blurred glass sphere that fills with
/// light when connected, a light streak racing around its rim while
/// connecting, and soft halo rings once the tunnel is up.
class _GlassConnectButton extends StatefulWidget {
  const _GlassConnectButton({
    required this.status,
    required this.onTap,
    required this.size,
    this.semanticLabel,
  });

  final VpnStatus status;
  final VoidCallback? onTap;
  final double size;
  final String? semanticLabel;

  @override
  State<_GlassConnectButton> createState() => _GlassConnectButtonState();
}

class _GlassConnectButtonState extends State<_GlassConnectButton> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: 1,
  );

  _Palette? _from;
  _Palette? _to;
  VpnStatus? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = _Palette.of(widget.status, context.colors);
    _from ??= p;
    _to = p;
    if (_lastStatus == null) {
      _lastStatus = widget.status;
      _syncLoops();
    }
  }

  @override
  void didUpdateWidget(_GlassConnectButton old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      _from = _current;
      _to = _Palette.of(widget.status, context.colors);
      _morph.forward(from: 0);
      if (widget.status == VpnStatus.connected) HapticFeedback.heavyImpact();
      if (widget.status == VpnStatus.error) HapticFeedback.vibrate();
      _lastStatus = widget.status;
      _syncLoops();
    }
  }

  _Palette get _current =>
      _Palette.lerp(_from!, _to!, Curves.easeInOutCubic.transform(_morph.value));

  void _syncLoops() {
    final s = widget.status;
    if (s == VpnStatus.connected) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
    }
    if (s == VpnStatus.connecting || s == VpnStatus.disconnecting) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spin.dispose();
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = widget.size;
    final orb = size * 0.62;
    return Pressable(
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onTap!();
            },
      scale: 0.95,
      semanticLabel: widget.semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulse, _spin, _morph]),
            builder: (context, _) {
              final p = _current;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HaloPainter(
                        palette: p,
                        colors: c,
                        orbRadius: orb / 2,
                        pulse: _pulse.value,
                        pulsing: _pulse.isAnimating,
                        spin: _spin.value,
                        spinning: _spin.isAnimating,
                      ),
                    ),
                  ),
                  ClipOval(
                    child: BackdropFilter(
                      filter: GlassSurface.backdrop,
                      child: CustomPaint(
                        size: Size.square(orb),
                        painter: _OrbPainter(tint: p.tint, dark: c.isDark),
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.power600,
                    size: size * 0.2,
                    color: p.icon,
                    shadows: [
                      Shadow(color: p.glow.withValues(alpha: 0.8 * p.glowAmount), blurRadius: 18),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Everything around the orb: ambient glow, halo rings, the rim light.
class _HaloPainter extends CustomPainter {
  _HaloPainter({
    required this.palette,
    required this.colors,
    required this.orbRadius,
    required this.pulse,
    required this.pulsing,
    required this.spin,
    required this.spinning,
  });

  final _Palette palette;
  final AppColors colors;
  final double orbRadius;
  final double pulse;
  final bool pulsing;
  final double spin;
  final bool spinning;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width / 2;
    final glowK = palette.glowAmount * colors.glowStrength;

    canvas.drawCircle(
      center,
      outer,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.glow.withValues(alpha: 0.55 * glowK),
            palette.glow.withValues(alpha: 0.16 * glowK),
            palette.glow.withValues(alpha: 0),
          ],
          stops: const [0.5, 0.72, 1],
        ).createShader(Rect.fromCircle(center: center, radius: outer)),
    );

    if (pulsing) {
      for (var i = 0; i < 3; i++) {
        final t = (pulse + i / 3) % 1;
        final r = orbRadius + (outer - orbRadius) * Curves.easeOut.transform(t);
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * (1 - t) + 0.5
            ..color = Colors.white.withValues(alpha: (1 - t) * 0.4 * colors.glowStrength),
        );
      }
    }

    final trackR = orbRadius + outer * 0.1;
    canvas.drawCircle(
      center,
      trackR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: colors.isDark ? 0.12 : 0.5),
    );
    if (spinning) {
      final rect = Rect.fromCircle(center: center, radius: trackR);
      final start = spin * 2 * math.pi;
      canvas.drawArc(
        rect,
        start,
        math.pi * 0.7,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            endAngle: math.pi * 0.7,
            colors: [Colors.white.withValues(alpha: 0), colors.accentStart, Colors.white],
            stops: const [0, 0.7, 1],
            transform: GradientRotation(start),
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter old) => true;
}

/// The glass sphere itself, painted over the blurred backdrop.
class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.tint, required this.dark});

  final Color tint;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = size.width / 2;

    // Body: light gathers at the bottom, as in a real lens.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.45),
          radius: 1.05,
          colors: [tint, tint.withValues(alpha: tint.a * 0.35), Colors.white.withValues(alpha: 0.04)],
          stops: const [0, 0.6, 1],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()..color = Colors.white.withValues(alpha: dark ? 0.04 : 0.18),
    );

    // Specular highlight in the upper-left.
    canvas.save();
    canvas.translate(center.dx - r * 0.28, center.dy - r * 0.5);
    canvas.rotate(-0.5);
    final hl = Rect.fromCenter(center: Offset.zero, width: r * 1.0, height: r * 0.5);
    canvas.drawOval(
      hl,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: dark ? 0.32 : 0.6),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(hl),
    );
    canvas.restore();

    // Rim.
    canvas.drawCircle(
      center,
      r - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.45),
          ],
          stops: const [0, 0.4, 0.6, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.tint != tint || old.dark != dark;
}
