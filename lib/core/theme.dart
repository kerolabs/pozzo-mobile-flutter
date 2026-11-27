import 'package:flutter/material.dart';

/// Color roles of the Pozzo style guide (Material 3, terracotta #B5472A with a gold accent #C9A845).
class PozzoTheme {
  const PozzoTheme._();

  static const _fontFamily = 'PlusJakartaSans';
  static const _brandContainer = Color(0xFFB5472A);
  static const _gold = Color(0xFFC9A845);

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF943015),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: _brandContainer,
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFF7A4436),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFB5A2),
    onSecondaryContainer: Color(0xFF321300),
    tertiary: _gold,
    onTertiary: Color(0xFF4F3D00),
    tertiaryContainer: _gold,
    onTertiaryContainer: Color(0xFF4F3D00),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFFFF8F6),
    onSurface: Color(0xFF241916),
    onSurfaceVariant: Color(0xFF57423C),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFF1ED),
    surfaceContainer: Color(0xFFFFE9E4),
    surfaceContainerHigh: Color(0xFFF9E3DE),
    surfaceContainerHighest: Color(0xFFF3DED9),
    outline: Color(0xFF8B716B),
    outlineVariant: Color(0xFFDEC0B8),
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB4A1),
    onPrimary: Color(0xFF611300),
    primaryContainer: _brandContainer,
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFFE7BDB1),
    onSecondary: Color(0xFF611300),
    secondaryContainer: Color(0xFF6C382B),
    onSecondaryContainer: Color(0xFFFFDBD1),
    tertiary: _gold,
    onTertiary: Color(0xFF241916),
    tertiaryContainer: _gold,
    onTertiaryContainer: Color(0xFF241916),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1B110E),
    onSurface: Color(0xFFF3DED9),
    onSurfaceVariant: Color(0xFFDEC0B8),
    surfaceContainerLowest: Color(0xFF1B110E),
    surfaceContainerLow: Color(0xFF231915),
    surfaceContainer: Color(0xFF281D1A),
    surfaceContainerHigh: Color(0xFF322824),
    surfaceContainerHighest: Color(0xFF3D322F),
    outline: Color(0xFFA68B84),
    outlineVariant: Color(0xFF57423C),
  );

  static ThemeData light() => _theme(lightScheme);

  static ThemeData dark() => _theme(darkScheme);

  static ThemeData _theme(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        fontFamily: _fontFamily,
        scaffoldBackgroundColor: scheme.surface,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
}
