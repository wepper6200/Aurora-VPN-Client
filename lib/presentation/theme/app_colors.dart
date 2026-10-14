import 'package:flutter/material.dart';

import '../../domain/settings/app_settings.dart';

/// Brand palette and semantic colors that Material's [ColorScheme] doesn't
/// cover (gradients, glass surfaces, connection states).
///
/// One instance per [DesignStyle] × brightness: Liquid Glass keeps the
/// teal → violet brand gradient over a vivid backdrop, Material 3 maps every
/// field onto the tonal [ColorScheme] roles.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.style,
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

  final DesignStyle style;
  final Brightness brightness;

  /// Teal end of the accent gradient (Material: `primary`).
  final Color accentStart;

  /// Violet end of the accent gradient (Material: `tertiary`).
  final Color accentEnd;

  final Color background;

  /// Second stop of the page background gradient.
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceElevated;

  /// Translucent fill for glass panels.
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

  /// Opacity multiplier for decorative glows (0 in Material 3).
  final double glowStrength;

  bool get isDark => brightness == Brightness.dark;
  bool get isGlass => style == DesignStyle.glass;
  bool get isMaterial => style == DesignStyle.material;

  /// Brand gradient; Material 3 has no gradients, so it degrades to the
  /// solid primary color there.
  LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentStart, isGlass ? accentEnd : accentStart],
  );

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundAlt, background],
  );

  /// Accent color in the middle of the gradient, for single-color usages.
  Color get accent => Color.lerp(accentStart, accentEnd, isGlass ? 0.5 : 0)!;

  /// Foreground on top of [accentGradient].
  Color get onAccent => isDark ? const Color(0xFF051512) : Colors.white;

  static const teal = Color(0xFF2DE2C5);
  static const violet = Color(0xFF8B5CF6);

  static const glassDark = AppColors(
    style: DesignStyle.glass,
    brightness: Brightness.dark,
    accentStart: Color(0xFF3BEBCF),
    accentEnd: Color(0xFF9B6BFF),
    background: Color(0xFF05060C),
    backgroundAlt: Color(0xFF0B1024),
    surface: Color(0xFF131A2E),
    surfaceElevated: Color(0xFF1A2238),
    surfaceGlass: Color(0x17FFFFFF),
    border: Color(0x24FFFFFF),
    textPrimary: Color(0xFFF4F6FC),
    textSecondary: Color(0xFFB8C0D6),
    textTertiary: Color(0xFF808AA4),
    success: Color(0xFF5FF5D9),
    warning: Color(0xFFFFC266),
    danger: Color(0xFFFF6B86),
    info: Color(0xFF6CB4FF),
    idle: Color(0xFF8792B0),
    shadow: Color(0x66000000),
    glowStrength: 1,
  );

  static const glassLight = AppColors(
    style: DesignStyle.glass,
    brightness: Brightness.light,
    accentStart: Color(0xFF0BA88F),
    accentEnd: Color(0xFF6D42EC),
    background: Color(0xFFEEF1FA),
    backgroundAlt: Color(0xFFE2E7F9),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF8F9FE),
    surfaceGlass: Color(0x8CFFFFFF),
    border: Color(0x1F101833),
    textPrimary: Color(0xFF0E1324),
    textSecondary: Color(0xFF465068),
    textTertiary: Color(0xFF7D86A0),
    success: Color(0xFF0B9B79),
    warning: Color(0xFFC77D00),
    danger: Color(0xFFE5395B),
    info: Color(0xFF2F7DE1),
    idle: Color(0xFF8E97AE),
    shadow: Color(0x241A2450),
    glowStrength: 0.7,
  );

  /// Kept for code that only needs "the brand palette" (logo, tray icons).
  static const dark = glassDark;
  static const light = glassLight;

  /// Material 3 palette: teal seed with the brand violet as tertiary.
  static ColorScheme materialScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(seedColor: teal, brightness: brightness);
    final v = ColorScheme.fromSeed(seedColor: violet, brightness: brightness);
    return base.copyWith(
      tertiary: v.primary,
      onTertiary: v.onPrimary,
      tertiaryContainer: v.primaryContainer,
      onTertiaryContainer: v.onPrimaryContainer,
    );
  }

  factory AppColors.material(ColorScheme s) {
    final dark = s.brightness == Brightness.dark;
    return AppColors(
      style: DesignStyle.material,
      brightness: s.brightness,
      accentStart: s.primary,
      accentEnd: s.tertiary,
      background: s.surface,
      backgroundAlt: s.surface,
      surface: s.surfaceContainer,
      surfaceElevated: s.surfaceContainerHigh,
      surfaceGlass: s.surfaceContainer,
      border: s.outlineVariant,
      textPrimary: s.onSurface,
      textSecondary: s.onSurfaceVariant,
      textTertiary: s.outline,
      success: dark ? const Color(0xFF7FDBA0) : const Color(0xFF1E6B3F),
      warning: dark ? const Color(0xFFF1C56B) : const Color(0xFF7A5900),
      danger: s.error,
      info: dark ? const Color(0xFF9ECAFF) : const Color(0xFF0061A4),
      idle: s.outline,
      shadow: Colors.transparent,
      glowStrength: 0,
    );
  }

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
      style: style,
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
      style: t < 0.5 ? style : other.style,
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
