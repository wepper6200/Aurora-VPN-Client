import 'package:flutter/material.dart';

/// Brand palette and semantic colors that Material's [ColorScheme] doesn't
/// cover (gradients, glass surfaces, connection states).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.accentStart,
    required this.accentEnd,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceGlass,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.idle,
    required this.shadow,
    required this.glowStrength,
  });

  final Brightness brightness;

  /// Teal end of the accent gradient.
  final Color accentStart;

  /// Violet end of the accent gradient.
  final Color accentEnd;

  final Color background;

  /// Second stop of the page background gradient.
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceElevated;

  /// Translucent fill for glassmorphic panels (used over a backdrop blur).
  final Color surfaceGlass;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Neutral color for the "disconnected" state.
  final Color idle;
  final Color shadow;

  /// Opacity multiplier for decorative glows (lower in light theme).
  final double glowStrength;

  bool get isDark => brightness == Brightness.dark;

  LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentStart, accentEnd],
  );

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundAlt, background],
  );

  /// Accent color in the middle of the gradient, for single-color usages.
  Color get accent => Color.lerp(accentStart, accentEnd, 0.5)!;

  static const dark = AppColors(
    brightness: Brightness.dark,
    accentStart: Color(0xFF2DE2C5),
    accentEnd: Color(0xFF8B5CF6),
    background: Color(0xFF0A0E19),
    backgroundAlt: Color(0xFF111833),
    surface: Color(0xFF131A2C),
    surfaceElevated: Color(0xFF1A2238),
    surfaceGlass: Color(0x991A2238),
    border: Color(0x1AFFFFFF),
    textPrimary: Color(0xFFF2F5FC),
    textSecondary: Color(0xFFA3ACC4),
    textTertiary: Color(0xFF69728C),
    success: Color(0xFF2DE2A6),
    warning: Color(0xFFFFB547),
    danger: Color(0xFFFF5C7A),
    info: Color(0xFF5CA8FF),
    idle: Color(0xFF5B6684),
    shadow: Color(0x66000000),
    glowStrength: 1,
  );

  static const light = AppColors(
    brightness: Brightness.light,
    accentStart: Color(0xFF0FB89E),
    accentEnd: Color(0xFF7246F0),
    background: Color(0xFFF3F5FB),
    backgroundAlt: Color(0xFFE9EDFA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF8F9FE),
    surfaceGlass: Color(0xB3FFFFFF),
    border: Color(0x14101833),
    textPrimary: Color(0xFF0E1324),
    textSecondary: Color(0xFF4E5770),
    textTertiary: Color(0xFF8790A8),
    success: Color(0xFF0FA97F),
    warning: Color(0xFFDB8B00),
    danger: Color(0xFFE5395B),
    info: Color(0xFF2F7DE1),
    idle: Color(0xFF9AA3BA),
    shadow: Color(0x241A2450),
    glowStrength: 0.55,
  );

  @override
  AppColors copyWith({
    Color? accentStart,
    Color? accentEnd,
    Color? background,
    Color? backgroundAlt,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceGlass,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? idle,
    Color? shadow,
    double? glowStrength,
  }) {
    return AppColors(
      brightness: brightness,
      accentStart: accentStart ?? this.accentStart,
      accentEnd: accentEnd ?? this.accentEnd,
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      idle: idle ?? this.idle,
      shadow: shadow ?? this.shadow,
      glowStrength: glowStrength ?? this.glowStrength,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      accentStart: c(accentStart, other.accentStart),
      accentEnd: c(accentEnd, other.accentEnd),
      background: c(background, other.background),
      backgroundAlt: c(backgroundAlt, other.backgroundAlt),
      surface: c(surface, other.surface),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      surfaceGlass: c(surfaceGlass, other.surfaceGlass),
      border: c(border, other.border),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      info: c(info, other.info),
      idle: c(idle, other.idle),
      shadow: c(shadow, other.shadow),
      glowStrength: glowStrength + (other.glowStrength - glowStrength) * t,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
