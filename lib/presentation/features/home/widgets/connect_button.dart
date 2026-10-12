import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../domain/vpn/vpn_core.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// Visual parameters of one connection state; lerped during transitions.
class _Palette {
  const _Palette({
    required this.fillA,
    required this.fillB,
    required this.icon,
    required this.glow,
    required this.glowAmount,
    required this.ring,
  });

  final Color fillA;
  final Color fillB;
  final Color icon;
  final Color glow;
  final double glowAmount;
  final Color ring;

  static _Palette of(VpnStatus s, AppColors c) {
    final onAccent = c.isDark ? const Color(0xFF071613) : Colors.white;
    switch (s) {
      case VpnStatus.disconnected:
        return _Palette(
          fillA: c.surfaceElevated,
          fillB: c.surface,
          icon: c.textSecondary,
          glow: c.accentEnd,
          glowAmount: 0.15,
          ring: c.border,
        );
      case VpnStatus.connecting:
      case VpnStatus.disconnecting:
        return _Palette(
          fillA: Color.alphaBlend(c.accentStart.withValues(alpha: 0.12), c.surfaceElevated),
          fillB: Color.alphaBlend(c.accentEnd.withValues(alpha: 0.12), c.surface),
          icon: c.accentStart,
          glow: c.accentStart,
          glowAmount: 0.45,
          ring: c.accentStart.withValues(alpha: 0.25),
        );
      case VpnStatus.connected:
        return _Palette(
          fillA: c.accentStart,
          fillB: c.accentEnd,
          icon: onAccent,
          glow: Color.lerp(c.accentStart, c.accentEnd, 0.4)!,
          glowAmount: 1,
          ring: c.accentStart.withValues(alpha: 0.35),
        );
      case VpnStatus.error:
        return _Palette(
          fillA: c.danger,
          fillB: Color.lerp(c.danger, c.accentEnd, 0.35)!,
          icon: Colors.white,
          glow: c.danger,
          glowAmount: 0.6,
          ring: c.danger.withValues(alpha: 0.35),
        );
    }
  }

  static _Palette lerp(_Palette a, _Palette b, double t) => _Palette(
    fillA: Color.lerp(a.fillA, b.fillA, t)!,
    fillB: Color.lerp(a.fillB, b.fillB, t)!,
    icon: Color.lerp(a.icon, b.icon, t)!,
    glow: Color.lerp(a.glow, b.glow, t)!,
    glowAmount: a.glowAmount + (b.glowAmount - a.glowAmount) * t,
    ring: Color.lerp(a.ring, b.ring, t)!,
  );
}

/// The big round connect/disconnect button with animated halo.
class ConnectButton extends StatefulWidget {
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
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );

  _Palette? _from;
  _Palette? _to;
  VpnStatus? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme changes re-resolve the palette without animating.
    final p = _Palette.of(widget.status, context.colors);
    _from ??= p;
    _to = p;
    if (_lastStatus == null) {
      _lastStatus = widget.status;
      _syncLoops();
    }
  }

  @override
  void didUpdateWidget(ConnectButton old) {
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
              return CustomPaint(
                painter: _ConnectPainter(
                  palette: p,
                  colors: c,
                  pulse: _pulse.value,
                  pulsing: widget.status == VpnStatus.connected || _pulse.isAnimating,
                  spin: _spin.value,
                  spinning: _spin.isAnimating,
                ),
                child: Center(
                  child: Icon(LucideIcons.power600, size: size * 0.2, color: p.icon),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ConnectPainter extends CustomPainter {
  _ConnectPainter({
    required this.palette,
    required this.colors,
    required this.pulse,
    required this.pulsing,
    required this.spin,
    required this.spinning,
  });

  final _Palette palette;
  final AppColors colors;
  final double pulse;
  final bool pulsing;
  final double spin;
  final bool spinning;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width / 2;
    final core = outer * 0.6;
    final trackR = core + outer * 0.09;
    final glowK = palette.glowAmount * colors.glowStrength;

    // Ambient glow.
    final glowRect = Rect.fromCircle(center: center, radius: outer);
    canvas.drawCircle(
      center,
      outer,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.glow.withValues(alpha: 0.38 * glowK),
            palette.glow.withValues(alpha: 0.12 * glowK),
            palette.glow.withValues(alpha: 0),
          ],
          stops: const [0.45, 0.7, 1],
        ).createShader(glowRect),
    );

    // Expanding pulse rings.
    if (pulsing) {
      for (var i = 0; i < 3; i++) {
        final t = (pulse + i / 3) % 1;
        final r = core + (outer - core) * Curves.easeOut.transform(t);
        final a = (1 - t) * 0.45 * colors.glowStrength;
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * (1 - t) + 0.5
            ..color = palette.glow.withValues(alpha: a),
        );
      }
    }

    // Track ring.
    canvas.drawCircle(
      center,
      trackR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = palette.ring,
    );

    // Spinner arc on the track.
    if (spinning) {
      final arcRect = Rect.fromCircle(center: center, radius: trackR);
      final start = spin * 2 * math.pi;
      canvas.drawArc(
        arcRect,
        start,
        math.pi * 0.55,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            endAngle: math.pi * 0.55,
            colors: [colors.accentStart.withValues(alpha: 0), colors.accentStart, colors.accentEnd],
            stops: const [0, 0.6, 1],
            transform: GradientRotation(start),
          ).createShader(arcRect),
      );
    }

    // Core disc.
    final coreRect = Rect.fromCircle(center: center, radius: core);
    canvas.drawCircle(
      center.translate(0, core * 0.08),
      core,
      Paint()
        ..color = colors.shadow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, core * 0.18),
    );
    canvas.drawCircle(
      center,
      core,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.fillA, palette.fillB],
        ).createShader(coreRect),
    );
    // Soft top highlight for depth.
    canvas.drawCircle(
      center,
      core,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0)],
          stops: const [0, 0.55],
        ).createShader(coreRect),
    );
    canvas.drawCircle(
      center,
      core,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: colors.isDark ? 0.08 : 0.5),
    );
  }

  @override
  bool shouldRepaint(_ConnectPainter old) => true;
}
