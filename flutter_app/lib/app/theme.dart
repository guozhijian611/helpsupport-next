import 'package:flutter/material.dart';

class AppTheme {
  static const _lightPrimary = Color(0xFFFF9585);
  static const _lightPrimaryNeighbor = Color(0xFFFF8D7F);
  static const _lightSecondary = Color(0xFFFCB08E);
  static const _lightSurface = Color(0xFFF7F7FA);
  static const _lightSurfaceLow = Color(0xFFF4F5F9);
  static const _lightSurfaceHigh = Color(0xFFF3F5FA);
  static const _lightSurfaceHighest = Color(0xFFEDEFF4);
  static const _lightOnSurface = Color(0xFF303236);
  static const _lightOnSurfaceVariant = Color(0xFF7D828A);
  static const _lightOutline = Color(0xFFE4E7EC);
  static const _lightOutlineVariant = Color(0xFFECE7E4);

  static const _darkPrimary = Color(0xFFFFB4A8);
  static const _darkPrimaryContainer = Color(0xFF7A4138);
  static const _darkSecondary = Color(0xFFFFCCB6);
  static const _darkSurface = Color(0xFF17191D);
  static const _darkSurfaceLow = Color(0xFF1E2126);
  static const _darkSurfaceHigh = Color(0xFF25292F);
  static const _darkSurfaceHighest = Color(0xFF2E333B);
  static const _darkOnSurface = Color(0xFFF3F4F7);
  static const _darkOnSurfaceVariant = Color(0xFFAEB4BE);
  static const _darkOutline = Color(0xFF454B55);
  static const _darkOutlineVariant = Color(0xFF333841);

  static ThemeData light() {
    return _theme(Brightness.light);
  }

  static ThemeData dark() {
    return _theme(Brightness.dark);
  }

  static ThemeData _theme(Brightness brightness) {
    final scheme = _colorScheme(brightness);
    final isDark = brightness == Brightness.dark;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    final selectedFill = isDark
        ? _darkPrimaryContainer
        : scheme.primaryContainer;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      canvasColor: scheme.surface,
      scaffoldBackgroundColor: scheme.surface,
      splashColor: scheme.primary.withValues(alpha: 0.08),
      highlightColor: scheme.primary.withValues(alpha: 0.04),
      dividerColor: scheme.outlineVariant,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 15,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.outline,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.24),
        selectionHandleColor: scheme.primary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.onSurfaceVariant,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerLowest,
          foregroundColor: scheme.primary,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.24)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.primary,
          backgroundColor: scheme.surfaceContainerLow,
          hoverColor: scheme.primary.withValues(alpha: 0.08),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.surfaceContainerHighest,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return isDark ? scheme.surfaceContainerHighest : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedFill;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return scheme.outlineVariant;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
        side: BorderSide(color: scheme.outline),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.onSurfaceVariant;
        }),
      ),
      chipTheme: ThemeData(brightness: brightness).chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        headerBackgroundColor: scheme.primary,
        headerForegroundColor: scheme.onPrimary,
        dividerColor: scheme.outlineVariant,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          if (states.contains(WidgetState.disabled)) {
            return Colors.transparent;
          }
          return null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurfaceVariant.withValues(alpha: 0.45);
          }
          return scheme.onSurface;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.primaryContainer.withValues(alpha: 0.8);
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.primary;
        }),
        todayBorder: BorderSide(color: scheme.primary, width: 1.4),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
        ),
        confirmButtonStyle: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        dialBackgroundColor: scheme.surfaceContainerLow,
        dialHandColor: scheme.primary,
        dialTextColor: scheme.onSurface,
        dayPeriodColor: scheme.surfaceContainerHigh,
        dayPeriodTextColor: scheme.onSurface,
        dayPeriodBorderSide: BorderSide(color: scheme.outlineVariant),
        entryModeIconColor: scheme.primary,
        hourMinuteColor: scheme.surfaceContainerHigh,
        hourMinuteTextColor: scheme.onSurface,
        helpTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  static ColorScheme _colorScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: brightness == Brightness.dark ? _darkPrimary : _lightPrimary,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) {
      return base.copyWith(
        primary: _darkPrimary,
        onPrimary: const Color(0xFF5F2F29),
        primaryContainer: _darkPrimaryContainer,
        onPrimaryContainer: const Color(0xFFFFDDD7),
        secondary: _darkSecondary,
        onSecondary: const Color(0xFF563624),
        secondaryContainer: const Color(0xFF704936),
        onSecondaryContainer: const Color(0xFFFFE1D4),
        tertiary: const Color(0xFFAEC6FF),
        onTertiary: const Color(0xFF19305F),
        tertiaryContainer: const Color(0xFF304778),
        onTertiaryContainer: const Color(0xFFDBE4FF),
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        surfaceContainerLowest: const Color(0xFF111317),
        surfaceContainerLow: _darkSurfaceLow,
        surfaceContainer: const Color(0xFF21252A),
        surfaceContainerHigh: _darkSurfaceHigh,
        surfaceContainerHighest: _darkSurfaceHighest,
        onSurfaceVariant: _darkOnSurfaceVariant,
        outline: _darkOutline,
        outlineVariant: _darkOutlineVariant,
        shadow: Colors.black,
        scrim: Colors.black,
      );
    }

    return base.copyWith(
      primary: _lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFDDD7),
      onPrimaryContainer: const Color(0xFF5D2F29),
      secondary: _lightSecondary,
      onSecondary: const Color(0xFF4E2F24),
      secondaryContainer: const Color(0xFFFFE2D4),
      onSecondaryContainer: const Color(0xFF5A392D),
      tertiary: const Color(0xFF5A81DA),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFDCE5FF),
      onTertiaryContainer: const Color(0xFF213B73),
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: _lightSurfaceLow,
      surfaceContainer: _lightSurfaceHigh,
      surfaceContainerHigh: const Color(0xFFF1F3F7),
      surfaceContainerHighest: _lightSurfaceHighest,
      onSurfaceVariant: _lightOnSurfaceVariant,
      outline: _lightOutline,
      outlineVariant: _lightOutlineVariant,
      shadow: const Color(0x14000000),
      scrim: const Color(0x66000000),
      surfaceTint: _lightPrimaryNeighbor,
    );
  }
}
