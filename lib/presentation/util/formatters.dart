import 'package:clock/clock.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';

/// A number and its unit, so the UI can style them separately.
typedef Measure = ({String value, String unit});

abstract final class Fmt {
  static const _units = ['B', 'KB', 'MB', 'GB', 'TB'];

  static Measure bytesParts(num bytes, String locale) {
    var v = bytes.toDouble().abs();
    var i = 0;
    while (v >= 1024 && i < _units.length - 1) {
      v /= 1024;
      i++;
    }
    final digits = i == 0 || v >= 100 ? 0 : 1;
    final f = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: digits);
    return (value: f.format(v), unit: _units[i]);
  }

  static String bytes(num bytes, String locale) {
    final p = bytesParts(bytes, locale);
    return '${p.value} ${p.unit}';
  }

  static Measure speedParts(num bytesPerSecond, String locale) {
    final p = bytesParts(bytesPerSecond, locale);
    return (value: p.value, unit: '${p.unit}/s');
  }

  static String speed(num bytesPerSecond, String locale) {
    final p = speedParts(bytesPerSecond, locale);
    return '${p.value} ${p.unit}';
  }

  /// `HH:MM:SS`.
  static String duration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  static String relative(DateTime t, AppLocalizations l10n, {DateTime? now}) {
    final diff = (now ?? clock.now()).difference(t);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
    return l10n.timeDaysAgo(diff.inDays);
  }

  /// Whole days until [t], rounding partial days up; negative if past.
  static int daysUntil(DateTime t, {DateTime? now}) {
    final diff = t.difference(now ?? clock.now());
    if (diff.isNegative) return -1;
    return (diff.inHours / 24).ceil();
  }
}
