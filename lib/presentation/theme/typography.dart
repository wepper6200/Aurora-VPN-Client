import 'package:flutter/material.dart';

/// Manrope is bundled as a single variable font, so every style sets the
/// `wght` axis explicitly in addition to [FontWeight].
abstract final class AppTypography {
  static const String family = 'Manrope';

  static TextStyle style(
    double size,
    FontWeight weight, {
    double? height,
    double letterSpacing = 0,
    Color? color,
    List<FontFeature>? features,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontFeatures: features,
    );
  }

  /// Monospaced style for logs and raw configs.
  static TextStyle mono(double size, {Color? color, FontWeight weight = FontWeight.w400}) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      height: 1.45,
      color: color,
    );
  }

  static TextTheme textTheme({required Color primary, required Color secondary}) {
    return TextTheme(
      displayLarge: style(56, FontWeight.w800, height: 1.05, letterSpacing: -1.5, color: primary),
      displayMedium: style(44, FontWeight.w800, height: 1.08, letterSpacing: -1.2, color: primary),
      displaySmall: style(36, FontWeight.w700, height: 1.1, letterSpacing: -0.8, color: primary),
      headlineLarge: style(32, FontWeight.w700, height: 1.15, letterSpacing: -0.6, color: primary),
      headlineMedium: style(28, FontWeight.w700, height: 1.2, letterSpacing: -0.5, color: primary),
      headlineSmall: style(24, FontWeight.w700, height: 1.25, letterSpacing: -0.3, color: primary),
      titleLarge: style(20, FontWeight.w700, height: 1.3, letterSpacing: -0.2, color: primary),
      titleMedium: style(16, FontWeight.w600, height: 1.35, color: primary),
      titleSmall: style(14, FontWeight.w600, height: 1.4, color: primary),
      bodyLarge: style(16, FontWeight.w500, height: 1.5, color: primary),
      bodyMedium: style(14, FontWeight.w500, height: 1.45, color: secondary),
      bodySmall: style(12, FontWeight.w500, height: 1.4, color: secondary),
      labelLarge: style(14, FontWeight.w700, height: 1.2, letterSpacing: 0.1, color: primary),
      labelMedium: style(12, FontWeight.w600, height: 1.2, letterSpacing: 0.2, color: secondary),
      labelSmall: style(11, FontWeight.w600, height: 1.2, letterSpacing: 0.4, color: secondary),
    );
  }
}

extension TextStyleWeightX on TextStyle {
  /// Changes the weight keeping the variable-font axis in sync.
  TextStyle weight(FontWeight w) =>
      copyWith(fontWeight: w, fontVariations: [FontVariation('wght', w.value.toDouble())]);

  /// Monospaced digits for counters, speeds and timers.
  TextStyle get tabular => copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
