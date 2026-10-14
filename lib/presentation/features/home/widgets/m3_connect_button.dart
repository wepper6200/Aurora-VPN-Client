import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../domain/vpn/vpn_core.dart';
import '../../../widgets/pressable.dart';

/// A polar "Material shape": `r(θ) = 1 + amplitude · cos(lobes · θ)`.
/// Circle, cookie, soft burst, clover… are all points of this family, so any
/// two of them can be morphed by interpolating the sampled radii.
class _Shape {
  const _Shape(this.lobes, this.amplitude);

  final int lobes;
  final double amplitude;

  static const circle = _Shape(0, 0);
  static const cookie9 = _Shape(9, 0.065);
  static const burst6 = _Shape(6, 0.11);
  static const pentagon = _Shape(5, 0.09);
  static const clover4 = _Shape(4, 0.10);
  static const sunny12 = _Shape(12, 0.045);

  /// Shapes cycled through while the tunnel is coming up — the M3
  /// Expressive loading indicator.
  static const loading = [burst6, cookie9, pentagon, clover4, sunny12];
}

/// All animated state of the button, advanced by one ticker. Painters listen
/// to it directly, so a frame repaints without rebuilding widgets.
class _Model extends ChangeNotifier {
  static const samples = 120;

  final Float64List radii = Float64List(samples)..fillRange(0, samples, 1);
  final Float64List _vel = Float64List(samples);
  Float64List _target = Float64List(samples)..fillRange(0, samples, 1);
  double _k = 380, _zeta = 0.8;

  double rotation = -math.pi / 2;
  double _spin = 0, _spinTarget = 0;

  double scale = 1;
  double _scaleVel = 0;

  Color fill = Colors.transparent, _fillTarget = Colors.transparent;
  Color icon = Colors.transparent, _iconTarget = Colors.transparent;
  Color ringColor = Colors.transparent, _ringColorTarget = Colors.transparent;
  Color track = Colors.transparent;

  /// 0 = ring hidden.
  double ringOpacity = 0, _ringOpacityTarget = 0;

  /// Wave height as a fraction of the button size.
  double amplitude = 0, _amplitudeTarget = 0;

  /// 0 = indeterminate (a growing and shrinking arc), 1 = a closed ring.
  double closed = 0, _closedTarget = 0;

  double time = 0;
  double headAngle = -math.pi / 2;
  double _headSpeed = 0;
  double wavePhase = 0;
  double _waveSpeed = 0;

  double shakeTime = 1;

  bool _initialized = false;

  void setShape(_Shape s, {double stiffness = 380, double damping = 0.8, bool snap = false}) {
    final t = Float64List(samples);
    for (var i = 0; i < samples; i++) {
      t[i] = 1 + s.amplitude * math.cos(s.lobes * i / samples * 2 * math.pi);
    }
    _target = t;
    _k = stiffness;
    _zeta = damping;
    if (snap) {
      radii.setAll(0, t);
      _vel.fillRange(0, samples, 0);
    }
  }

  void configure({
    required Color fill,
    required Color icon,
    required Color ring,
    required Color track,
    required double ringOpacity,
    required double amplitude,
    required double closed,
    required double spin,
    required double headSpeed,
    required double waveSpeed,
  }) {
    _fillTarget = fill;
    _iconTarget = icon;
    _ringColorTarget = ring;
    this.track = track;
    _ringOpacityTarget = ringOpacity;
    _amplitudeTarget = amplitude;
    _closedTarget = closed;
    _spinTarget = spin;
    _headSpeed = headSpeed;
    _waveSpeed = waveSpeed;
    if (!_initialized) {
      _initialized = true;
      this.fill = fill;
      this.icon = icon;
      ringColor = ring;
      this.ringOpacity = ringOpacity;
      this.amplitude = amplitude;
      this.closed = closed;
    }
  }

  void kick(double v) => _scaleVel += v;

  void shake() => shakeTime = 0;

  /// Advances physics by [dt] seconds. Returns false once nothing moves.
  bool step(double dt) {
    const sub = 4;
    final h = dt / sub;
    final c = 2 * _zeta * math.sqrt(_k);
    var moving = false;
    for (var s = 0; s < sub; s++) {
      for (var i = 0; i < samples; i++) {
        final f = -_k * (radii[i] - _target[i]) - c * _vel[i];
        _vel[i] += f * h;
        radii[i] += _vel[i] * h;
      }
      final fs = -520 * (scale - 1) - 2 * 0.32 * math.sqrt(520) * _scaleVel;
      _scaleVel += fs * h;
      scale += _scaleVel * h;
    }
    for (var i = 0; i < samples; i++) {
      if (_vel[i].abs() > 1e-4 || (radii[i] - _target[i]).abs() > 1e-4) {
        moving = true;
        break;
      }
    }
    if (_scaleVel.abs() > 1e-4 || (scale - 1).abs() > 1e-4) moving = true;

    final e = 1 - math.exp(-dt * 9);
    double ease(double a, double b) => a + (b - a) * e;
    // Snaps once visually identical, so the ticker can come to rest.
    Color easeC(Color a, Color b) {
      final c = Color.lerp(a, b, e)!;
      final close =
          (c.r - b.r).abs() < 0.002 &&
          (c.g - b.g).abs() < 0.002 &&
          (c.b - b.b).abs() < 0.002 &&
          (c.a - b.a).abs() < 0.002;
      return close ? b : c;
    }

    fill = easeC(fill, _fillTarget);
    icon = easeC(icon, _iconTarget);
    ringColor = easeC(ringColor, _ringColorTarget);
    ringOpacity = ease(ringOpacity, _ringOpacityTarget);
    amplitude = ease(amplitude, _amplitudeTarget);
    closed = ease(closed, _closedTarget);
    _spin += (_spinTarget - _spin) * (1 - math.exp(-dt * 3));
    rotation += _spin * dt;

    time += dt;
    headAngle += _headSpeed * dt;
    wavePhase += _waveSpeed * dt;
    if (shakeTime < 1) shakeTime += dt;

    if ((ringOpacity - _ringOpacityTarget).abs() > 0.002 ||
        (closed - _closedTarget).abs() > 0.002 ||
        (amplitude - _amplitudeTarget).abs() > 1e-5 ||
        fill != _fillTarget ||
        icon != _iconTarget ||
        _spin.abs() > 0.005 ||
        _spinTarget != 0 ||
        (ringOpacity > 0.01 && (_headSpeed != 0 || _waveSpeed != 0)) ||
        shakeTime < 1) {
      moving = true;
    }
    notifyListeners();
    return moving;
  }
}

/// Material 3 Expressive connect button.
///
/// - **Disconnected:** a calm circle in `surfaceContainerHighest`.
/// - **Connecting:** the shape cycles through Expressive shapes and spins
///   while a wavy "snake" chases itself around it.
/// - **Connected:** the shape settles into a slowly turning 9-point cookie in
///   `primaryContainer` with a bounce, and the snake closes into a gently
///   rippling ring.
/// - **Error:** a clover in `errorContainer` with a short shake.
class M3ConnectButton extends StatefulWidget {
  const M3ConnectButton({
    super.key,
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
  State<M3ConnectButton> createState() => _M3ConnectButtonState();
}

class _M3ConnectButtonState extends State<M3ConnectButton> with SingleTickerProviderStateMixin {
  final _model = _Model();
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;
  double _sinceShape = 0;
  int _shapeIndex = 0;
  bool _reduceMotion = false;
  VpnStatus? _applied;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Theme changes re-resolve the colors; the first call also sets the shape.
    _apply(initial: _applied == null);
  }

  @override
  void didUpdateWidget(M3ConnectButton old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      if (widget.status == VpnStatus.connected) HapticFeedback.heavyImpact();
      if (widget.status == VpnStatus.error) HapticFeedback.vibrate();
      _apply();
    }
  }

  void _apply({bool initial = false}) {
    final s = Theme.of(context).colorScheme;
    final status = widget.status;
    final changed = _applied != status;
    _applied = status;
    final rm = _reduceMotion;
    final size = widget.size;

    switch (status) {
      case VpnStatus.disconnected:
        if (changed) _model.setShape(_Shape.circle, stiffness: 420, damping: 0.85, snap: initial);
        _model.configure(
          fill: s.surfaceContainerHighest,
          icon: s.onSurfaceVariant,
          ring: s.primary,
          track: s.secondaryContainer,
          ringOpacity: 0,
          amplitude: 0,
          closed: 0,
          spin: 0,
          headSpeed: 0,
          waveSpeed: 0,
        );
      case VpnStatus.connecting:
        if (changed) {
          _shapeIndex = 0;
          _sinceShape = 0;
          _model.setShape(_Shape.loading.first, stiffness: 800, damping: 0.6, snap: initial);
        }
        _model.configure(
          fill: s.tertiaryContainer,
          icon: s.onTertiaryContainer,
          ring: s.primary,
          track: s.secondaryContainer,
          ringOpacity: 1,
          amplitude: rm ? 0 : size * 0.013,
          closed: 0,
          spin: rm ? 0 : 2.4,
          headSpeed: rm ? 0 : 4.6,
          waveSpeed: rm ? 0 : 9,
        );
      case VpnStatus.connected:
        if (changed) {
          _model.setShape(_Shape.cookie9, damping: 0.5, snap: initial);
          if (!initial && !rm) _model.kick(2.6);
        }
        _model.configure(
          fill: s.primaryContainer,
          icon: s.onPrimaryContainer,
          ring: s.primary,
          track: s.secondaryContainer,
          ringOpacity: 1,
          amplitude: rm ? 0 : size * 0.006,
          closed: 1,
          spin: rm ? 0 : 0.14,
          headSpeed: rm ? 0 : 0.25,
          waveSpeed: rm ? 0 : 2.2,
        );
      case VpnStatus.disconnecting:
        if (changed) _model.setShape(_Shape.circle, stiffness: 500, damping: 0.9);
        _model.configure(
          fill: s.tertiaryContainer,
          icon: s.onTertiaryContainer,
          ring: s.tertiary,
          track: s.secondaryContainer,
          ringOpacity: 1,
          amplitude: rm ? 0 : size * 0.01,
          closed: 0,
          spin: rm ? 0 : 1.2,
          headSpeed: rm ? 0 : 4,
          waveSpeed: rm ? 0 : 7,
        );
      case VpnStatus.error:
        if (changed) {
          _model.setShape(_Shape.clover4, stiffness: 800, damping: 0.6, snap: initial);
          if (!initial && !rm) _model.shake();
        }
        _model.configure(
          fill: s.errorContainer,
          icon: s.onErrorContainer,
          ring: s.error,
          track: s.secondaryContainer,
          ringOpacity: 0,
          amplitude: 0,
          closed: 0,
          spin: 0,
          headSpeed: 0,
          waveSpeed: 0,
        );
    }
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;

    if (widget.status == VpnStatus.connecting && !_reduceMotion) {
      _sinceShape += dt;
      if (_sinceShape > 0.65) {
        _sinceShape = 0;
        _shapeIndex = (_shapeIndex + 1) % _Shape.loading.length;
        _model.setShape(_Shape.loading[_shapeIndex], stiffness: 800, damping: 0.6);
      }
    }

    final moving = _model.step(dt);
    final looping =
        widget.status == VpnStatus.connecting ||
        widget.status == VpnStatus.disconnecting ||
        (widget.status == VpnStatus.connected && !_reduceMotion);
    if (!moving && !looping) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Pressable(
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onTap!();
            },
      scale: 0.94,
      semanticLabel: widget.semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _model,
            builder: (context, child) {
              final t = _model.shakeTime;
              final dx = t < 1 ? math.sin(t * 42) * size * 0.035 * math.exp(-t * 7) : 0.0;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: CustomPaint(
                  painter: _M3Painter(_model),
                  child: Center(
                    child: Transform.scale(
                      scale: _model.scale,
                      child: Icon(LucideIcons.power600, size: size * 0.2, color: _model.icon),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _M3Painter extends CustomPainter {
  _M3Painter(this.m) : super(repaint: m);

  final _Model m;

  static const _waves = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.width;

    // Morphing shape.
    final shapeR = unit * 0.3 * m.scale;
    final path = Path();
    const n = _Model.samples;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi + m.rotation;
      final r = shapeR * m.radii[i];
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = m.fill);

    // Wavy "snake" ring.
    if (m.ringOpacity < 0.01) return;
    final ringR = unit * 0.45;
    final stroke = unit * 0.027;
    final indeterminate = 0.1 + 0.6 * (0.5 - 0.5 * math.cos(2 * math.pi * m.time / 1.5));
    final sweepFrac = indeterminate + (1 - indeterminate) * m.closed;
    final sweep = sweepFrac * 2 * math.pi;
    final start = m.headAngle - sweep * 0.5;
    final amp = m.amplitude;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = m.ringColor.withValues(alpha: m.ringColor.a * m.ringOpacity);

    final full = sweepFrac > 0.995;
    final wave = Path();
    final steps = math.max(24, (sweepFrac * 360).round());
    for (var i = 0; i <= steps; i++) {
      final a = full ? i / steps * 2 * math.pi : start + sweep * i / steps;
      final r = ringR + amp * math.sin(_waves * a + m.wavePhase);
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? wave.moveTo(p.dx, p.dy) : wave.lineTo(p.dx, p.dy);
    }
    if (full) wave.close();
    canvas.drawPath(wave, ringPaint);

    // Remaining track with gaps on both sides of the snake (M3 2024 style).
    final gap = (stroke * 1.6) / ringR + stroke / ringR;
    final remaining = 2 * math.pi - sweep - 2 * gap;
    if (remaining > 0.02) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringR),
        start + sweep + gap,
        remaining,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = m.track.withValues(alpha: m.track.a * m.ringOpacity * (1 - m.closed)),
      );
    }
  }

  @override
  bool shouldRepaint(_M3Painter old) => old.m != m;
}
