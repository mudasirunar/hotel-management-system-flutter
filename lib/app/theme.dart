import 'package:flutter/material.dart';

abstract final class HotelTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    // Crisp light-slate canvas with pure white cards in light mode; deep obsidian with elevated surfaces in dark mode.
    final background = dark ? const Color(0xFF0C1410) : const Color(0xFFF8FAFC);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF007F5F),
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFF34D399) : const Color(0xFF007F5F),
          onPrimary: dark ? const Color(0xFF052E22) : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF134E39)
              : const Color(0xFFD1FAE5),
          onPrimaryContainer: dark
              ? const Color(0xFF6EE7B7)
              : const Color(0xFF064E3B),
          secondary: dark ? const Color(0xFF87DBB5) : const Color(0xFF0F766E),
          onSecondary: dark ? const Color(0xFF103C2C) : Colors.white,
          secondaryContainer: dark
              ? const Color(0xFF1F3D30)
              : const Color(0xFFCCFBF1),
          onSecondaryContainer: dark
              ? const Color(0xFF99F6E4)
              : const Color(0xFF115E59),
          surface: dark ? const Color(0xFF16231D) : Colors.white,
          surfaceDim: dark ? const Color(0xFF0C1410) : const Color(0xFFF1F5F9),
          surfaceBright: dark ? const Color(0xFF22352B) : Colors.white,
          surfaceContainerLowest: dark ? const Color(0xFF090F0C) : Colors.white,
          surfaceContainerLow: dark
              ? const Color(0xFF121D17)
              : const Color(0xFFF8FAFC),
          surfaceContainer: dark
              ? const Color(0xFF1C2B23)
              : const Color(0xFFF1F5F9),
          surfaceContainerHigh: dark
              ? const Color(0xFF23352C)
              : const Color(0xFFE2E8F0),
          surfaceContainerHighest: dark
              ? const Color(0xFF2A3F34)
              : const Color(0xFFCBD5E1),
          onSurface: dark ? const Color(0xFFF1F5F2) : const Color(0xFF0F172A),
          onSurfaceVariant: dark
              ? const Color(0xFF9CB3A6)
              : const Color(0xFF475569),
          outline: dark ? const Color(0xFF658071) : const Color(0xFF94A3B8),
          outlineVariant: dark
              ? const Color(0xFF273D31)
              : const Color(0xFFE2E8F0),
          error: const Color(0xFFBA1A1A),
          onError: Colors.white,
          errorContainer: dark
              ? const Color(0xFF4C272E)
              : const Color(0xFFFCE8E9),
          onErrorContainer: dark
              ? const Color(0xFFFFDAD8)
              : const Color(0xFF7B202C),
          inverseSurface: dark
              ? const Color(0xFFF1F5F2)
              : const Color(0xFF0F172A),
          onInverseSurface: dark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF1F5F2),
          inversePrimary: dark
              ? const Color(0xFF007F5F)
              : const Color(0xFF34D399),
          surfaceTint: Colors.transparent,
        );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outlineVariant),
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
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
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
