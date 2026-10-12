// Renders every platform icon from the in-app logo geometry
// (AppLogo.paintMark), so the launcher, window and tray icons always match.
//
//   flutter test tool/icons/render_icons_test.dart
//
// Writes Android mipmaps (legacy + adaptive foreground + monochrome),
// windows/runner/resources/app_icon.ico and assets/tray/tray{,_off}.ico.
@Tags(['tool'])
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aurora_vpn/presentation/shell/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _bgTop = Color(0xFF1A2140);
const _bgBottom = Color(0xFF0A0E19);
const _trayOff = Color(0xFF9AA3B5);

/// Android density buckets → scale of a 48dp icon.
const _densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};

Future<Uint8List> _render(int px, void Function(Canvas canvas, double s) paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paint(canvas, px.toDouble());
  final image = await recorder.endRecording().toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// Rounded dark tile with the gradient mark (legacy Android, Windows exe).
void _tile(Canvas canvas, double s, {double mark = 0.6}) {
  final rect = Offset.zero & Size.square(s);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22)),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_bgTop, _bgBottom],
      ).createShader(rect),
  );
  final m = s * mark;
  AppLogo.paintMark(canvas, Rect.fromCenter(center: rect.center, width: m, height: m));
}

/// Mark only, centred in an adaptive-icon canvas (108dp, 66dp safe zone).
void _foreground(Canvas canvas, double s, {Color? color}) {
  final m = s * 0.46;
  AppLogo.paintMark(
    canvas,
    Rect.fromCenter(center: Offset(s / 2, s / 2), width: m, height: m),
    color: color,
  );
}

void _mark(Canvas canvas, double s, {Color? color}) {
  final m = s * 0.94;
  AppLogo.paintMark(
    canvas,
    Rect.fromCenter(center: Offset(s / 2, s / 2), width: m, height: m),
    color: color,
  );
}

/// ICO container with PNG-compressed entries (Windows Vista+).
Uint8List _ico(Map<int, Uint8List> pngs) {
  final sizes = pngs.keys.toList()..sort();
  final out = BytesBuilder();
  final header = ByteData(6 + 16 * sizes.length);
  header
    ..setUint16(0, 0, Endian.little)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, sizes.length, Endian.little);
  var offset = header.lengthInBytes;
  for (var i = 0; i < sizes.length; i++) {
    final px = sizes[i];
    final png = pngs[px]!;
    final e = 6 + 16 * i;
    header
      ..setUint8(e, px >= 256 ? 0 : px)
      ..setUint8(e + 1, px >= 256 ? 0 : px)
      ..setUint16(e + 4, 1, Endian.little)
      ..setUint16(e + 6, 32, Endian.little)
      ..setUint32(e + 8, png.length, Endian.little)
      ..setUint32(e + 12, offset, Endian.little);
    offset += png.length;
  }
  out.add(header.buffer.asUint8List());
  for (final px in sizes) {
    out.add(pngs[px]!);
  }
  return out.toBytes();
}

void _write(String path, List<int> bytes) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes);
}

void main() {
  testWidgets('render icons', (tester) async {
    await tester.runAsync(() async {
      const res = 'android/app/src/main/res';
      for (final MapEntry(key: bucket, value: k) in _densities.entries) {
        _write(
          '$res/mipmap-$bucket/ic_launcher.png',
          await _render((48 * k).round(), (c, s) => _tile(c, s)),
        );
        final fg = (108 * k).round();
        _write('$res/mipmap-$bucket/ic_launcher_foreground.png', await _render(fg, _foreground));
        _write(
          '$res/mipmap-$bucket/ic_launcher_monochrome.png',
          await _render(fg, (c, s) => _foreground(c, s, color: Colors.white)),
        );
      }

      // Small sizes get a bigger mark so it stays legible.
      _write(
        'windows/runner/resources/app_icon.ico',
        _ico({
          for (final px in [16, 20, 24, 32, 40, 48, 64, 128, 256])
            px: await _render(px, (c, s) => _tile(c, s, mark: px <= 32 ? 0.74 : 0.6)),
        }),
      );

      const traySizes = [16, 20, 24, 32, 40, 48, 64];
      _write(
        'assets/tray/tray.ico',
        _ico({for (final px in traySizes) px: await _render(px, (c, s) => _mark(c, s))}),
      );
      _write(
        'assets/tray/tray_off.ico',
        _ico({
          for (final px in traySizes) px: await _render(px, (c, s) => _mark(c, s, color: _trayOff)),
        }),
      );

      // Preview for review (not shipped).
      _write('build/icons/preview_512.png', await _render(512, (c, s) => _tile(c, s)));
    });
  });
}
