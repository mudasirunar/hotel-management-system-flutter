import 'package:flutter/material.dart';

abstract final class HotelTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    // Forest surfaces and a saturated emerald accent keep dark mode clear and lively.
    final background = dark ? const Color(0xFF141F1B) : const Color(0xFFE8F3EC);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF007F5F),
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFF34D399) : const Color(0xFF007F5F),
          onPrimary: dark ? const Color(0xFF052E22) : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF164D39)
              : const Color(0xFFDDF5E8),
          onPrimaryContainer: dark
              ? const Color(0xFFBAF7D9)
              : const Color(0xFF00563F),
          secondary: dark ? const Color(0xFF87DBB5) : const Color(0xFF36715B),
          onSecondary: dark ? const Color(0xFF103C2C) : Colors.white,
          secondaryContainer: dark
              ? const Color(0xFF294C3D)
              : const Color(0xFFCCEBD9),
          onSecondaryContainer: dark
              ? const Color(0xFFCFF5DF)
              : const Color(0xFF136143),
          surface: dark ? const Color(0xFF24362F) : const Color(0xFFDFF2E7),
          surfaceDim: dark ? const Color(0xFF141F1B) : const Color(0xFFD4E8DC),
          surfaceBright: dark
              ? const Color(0xFF3B5147)
              : const Color(0xFFF2FCF6),
          surfaceContainerLowest: dark
              ? const Color(0xFF101A15)
              : const Color(0xFFF5FCF7),
          surfaceContainerLow: dark
              ? const Color(0xFF1D2D25)
              : const Color(0xFFE7F6ED),
          surfaceContainer: dark
              ? const Color(0xFF2A3F34)
              : const Color(0xFFDFF2E7),
          surfaceContainerHigh: dark
              ? const Color(0xFF32483D)
              : const Color(0xFFD5ECDD),
          surfaceContainerHighest: dark
              ? const Color(0xFF3B5147)
              : const Color(0xFFC9E4D4),
          onSurface: dark ? const Color(0xFFEEF8F2) : const Color(0xFF1E3027),
          onSurfaceVariant: dark
              ? const Color(0xFFBED1C5)
              : const Color(0xFF4D6557),
          outline: dark ? const Color(0xFF87A393) : const Color(0xFF6F8778),
          outlineVariant: dark
              ? const Color(0xFF496456)
              : const Color(0xFFB7D5C3),
          error: dark ? const Color(0xFFFFB4AF) : const Color(0xFFB32632),
          onError: dark ? const Color(0xFF591C22) : Colors.white,
          errorContainer: dark
              ? const Color(0xFF4C272E)
              : const Color(0xFFFCE8E9),
          onErrorContainer: dark
              ? const Color(0xFFFFDAD8)
              : const Color(0xFF7B202C),
          inverseSurface: dark
              ? const Color(0xFFEEF8F2)
              : const Color(0xFF2A3F34),
          onInverseSurface: dark
              ? const Color(0xFF1E3027)
              : const Color(0xFFEEF8F2),
          inversePrimary: dark
              ? const Color(0xFF007F5F)
              : const Color(0xFF34D399),
          surfaceTint: Colors.transparent,
        );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outline),
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        errorMaxLines: 3,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        helperStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
