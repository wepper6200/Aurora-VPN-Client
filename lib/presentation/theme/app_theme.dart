import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/settings/app_settings.dart';
import '../router/transitions.dart';
import 'app_colors.dart';
import 'tokens.dart';
import 'typography.dart';

abstract final class AppTheme {
  static ThemeData of(DesignStyle style, Brightness brightness) => switch (style) {
    DesignStyle.material => _material(brightness),
    DesignStyle.glass => _glass(
      brightness == Brightness.dark ? AppColors.glassDark : AppColors.glassLight,
    ),
  };

  /// Material 3: shared axis X between a page and its sub-pages.
  static const _transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: SharedAxisPageTransitionsBuilder(),
      TargetPlatform.windows: SharedAxisPageTransitionsBuilder(),
      TargetPlatform.linux: SharedAxisPageTransitionsBuilder(),
      TargetPlatform.macOS: SharedAxisPageTransitionsBuilder(),
    },
  );

  /// Liquid Glass: the iOS parallax slide (with swipe-back).
  static const _glassTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  /// Material 3 Expressive: tonal roles straight from the seed scheme, pill
  /// buttons and the 2024 indicators. Text stays on the bundled Manrope so
  /// Android and Windows render identically.
  static ThemeData _material(Brightness brightness) {
    final s = AppColors.materialScheme(brightness);
    final c = AppColors.material(s);
    final text = AppTypography.textTheme(primary: s.onSurface, secondary: s.onSurfaceVariant);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: s,
      fontFamily: AppTypography.family,
      textTheme: text,
    );
    const pill = StadiumBorder();
    final field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide.none,
    );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: s.surface,
      canvasColor: s.surface,
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
        foregroundColor: s.onSurface,
        systemOverlayStyle: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: s.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
      ),
      dividerTheme: DividerThemeData(color: s.outlineVariant, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: pill,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: pill,
          side: BorderSide(color: s.outlineVariant),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: pill, textStyle: text.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
        hintStyle: text.bodyLarge!.copyWith(color: s.onSurfaceVariant),
        prefixIconColor: s.onSurfaceVariant,
        suffixIconColor: s.onSurfaceVariant,
        border: field,
        enabledBorder: field,
        focusedBorder: field.copyWith(borderSide: BorderSide(color: s.primary, width: 2)),
        errorBorder: field.copyWith(borderSide: BorderSide(color: s.error)),
        focusedErrorBorder: field.copyWith(borderSide: BorderSide(color: s.error, width: 2)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 80,
        indicatorColor: s.secondaryContainer,
        indicatorShape: pill,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (st) => IconThemeData(
            size: 24,
            color: st.contains(WidgetState.selected)
                ? s.onSecondaryContainer
                : s.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (st) => text.labelMedium!.copyWith(
            color: st.contains(WidgetState.selected) ? s.onSurface : s.onSurfaceVariant,
            fontWeight: st.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: s.surfaceContainer,
        elevation: 0,
        minWidth: 88,
        groupAlignment: -1,
        indicatorColor: s.secondaryContainer,
        indicatorShape: pill,
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(color: s.onSecondaryContainer, size: 24),
        unselectedIconTheme: IconThemeData(color: s.onSurfaceVariant, size: 24),
        selectedLabelTextStyle: text.labelMedium!.copyWith(
          color: s.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: text.labelMedium,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xs)),
        side: BorderSide(color: s.outlineVariant),
        selectedColor: s.secondaryContainer,
        // Compact enough that a row of five filters fits a 360dp phone.
        padding: const EdgeInsets.symmetric(horizontal: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: text.labelMedium!.copyWith(color: s.onSurfaceVariant),
        secondaryLabelStyle: text.labelMedium!.copyWith(color: s.onSecondaryContainer),
        showCheckmark: true,
        checkmarkColor: s.onSecondaryContainer,
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? const Icon(Icons.check_rounded) : null,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: s.secondaryContainer,
          selectedForegroundColor: s.onSecondaryContainer,
          side: BorderSide(color: s.outline),
          textStyle: text.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: s.onSurfaceVariant,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xxl)),
        titleTextStyle: text.headlineSmall!.copyWith(color: s.onSurface),
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surfaceContainerLow,
        modalBackgroundColor: s.surfaceContainerLow,
        showDragHandle: true,
        dragHandleColor: s.onSurfaceVariant.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: s.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        textStyle: text.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: s.inverseSurface,
        contentTextStyle: text.bodyMedium!.copyWith(color: s.onInverseSurface),
        actionTextColor: s.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
      ),
      // ignore: deprecated_member_use
      progressIndicatorTheme: const ProgressIndicatorThemeData(year2023: false),
      // ignore: deprecated_member_use
      sliderTheme: const SliderThemeData(year2023: false),
      pageTransitionsTheme: _transitions,
    );
  }

  static ThemeData _glass(AppColors c) {
    final scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.accentStart,
      onPrimary: c.isDark ? const Color(0xFF04201B) : Colors.white,
      primaryContainer: c.accentStart.withValues(alpha: 0.18),
      onPrimaryContainer: c.textPrimary,
      secondary: c.accentEnd,
      onSecondary: Colors.white,
      secondaryContainer: c.accentEnd.withValues(alpha: 0.18),
      onSecondaryContainer: c.textPrimary,
      tertiary: c.info,
      onTertiary: Colors.white,
      error: c.danger,
      onError: Colors.white,
      errorContainer: c.danger.withValues(alpha: 0.16),
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceElevated,
      surfaceContainerHighest: c.surfaceElevated,
      outline: c.border,
      outlineVariant: c.border,
      shadow: c.shadow,
      scrim: Colors.black54,
      inverseSurface: c.textPrimary,
      onInverseSurface: c.background,
      inversePrimary: c.accentEnd,
    );

    final text = AppTypography.textTheme(primary: c.textPrimary, secondary: c.textSecondary);
    final roundedMd = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md));
    final buttonText = text.labelLarge;

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.family,
      textTheme: text,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: [c],
      iconTheme: IconThemeData(color: c.textPrimary, size: 22),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        foregroundColor: c.textPrimary,
        systemOverlayStyle: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: c.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: roundedMd,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: roundedMd,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: roundedMd,
          side: BorderSide(color: c.border),
          foregroundColor: c.textPrimary,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accentStart,
          shape: roundedMd,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        hintStyle: text.bodyMedium?.copyWith(color: c.textTertiary),
        labelStyle: text.bodyMedium,
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: c.accentStart, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: c.danger),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: c.accentStart.withValues(alpha: c.isDark ? 0.16 : 0.14),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected) ? c.accentStart : c.textTertiary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall!.copyWith(
            color: s.contains(WidgetState.selected) ? c.textPrimary : c.textTertiary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        minWidth: 76,
        groupAlignment: -1,
        indicatorColor: c.accentStart.withValues(alpha: c.isDark ? 0.16 : 0.14),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(color: c.accentStart, size: 24),
        unselectedIconTheme: IconThemeData(color: c.textTertiary, size: 24),
        selectedLabelTextStyle: text.labelSmall!.copyWith(color: c.textPrimary),
        unselectedLabelTextStyle: text.labelSmall!.copyWith(color: c.textTertiary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceElevated,
        selectedColor: c.accentStart.withValues(alpha: 0.18),
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
        labelStyle: text.labelMedium!.copyWith(color: c.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : c.textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accentStart : c.surfaceElevated,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : c.border,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accentStart,
        inactiveTrackColor: c.surfaceElevated,
        thumbColor: c.accentStart,
        overlayColor: c.accentStart.withValues(alpha: 0.12),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: c.surfaceElevated,
          selectedBackgroundColor: c.accentStart.withValues(alpha: 0.18),
          selectedForegroundColor: c.textPrimary,
          foregroundColor: c.textSecondary,
          side: BorderSide(color: c.border),
          textStyle: text.labelMedium,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceElevated.withValues(alpha: 0.97),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xxl)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceElevated.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surfaceElevated.withValues(alpha: 0.94),
        showDragHandle: true,
        dragHandleColor: c.textTertiary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: c.border),
        ),
        textStyle: text.bodyMedium!.copyWith(color: c.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.isDark ? c.surfaceElevated : c.textPrimary,
        contentTextStyle: text.bodyMedium!.copyWith(color: c.isDark ? c.textPrimary : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        elevation: 0,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.isDark ? c.surfaceElevated : c.textPrimary,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        textStyle: text.labelSmall!.copyWith(color: c.isDark ? c.textPrimary : Colors.white),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accentStart,
        linearTrackColor: c.surfaceElevated,
        circularTrackColor: Colors.transparent,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(c.textTertiary.withValues(alpha: 0.4)),
        radius: const Radius.circular(AppRadii.pill),
        thickness: const WidgetStatePropertyAll(4),
      ),
      pageTransitionsTheme: _glassTransitions,
    );
  }
}
