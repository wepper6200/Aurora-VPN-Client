import 'package:flutter/animation.dart';

/// Corner radii used across the design system.
abstract final class AppRadii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 999;
}

/// 4-pt spacing scale.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Horizontal padding of page content.
  static const double page = 20;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration stagger = Duration(milliseconds: 45);
  static const Duration pulse = Duration(milliseconds: 1800);
}

abstract final class AppCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve spring = Curves.easeOutBack;
}

/// Layout breakpoints (logical pixels).
abstract final class AppBreakpoints {
  /// Above this width mobile layouts switch to the navigation rail.
  static const double rail = 840;

  /// Max width of the main content column on wide windows.
  static const double contentMaxWidth = 720;
}
