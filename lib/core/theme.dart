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

  static ThemeData light() => _theme(lightScheme, PozzoStatusColors.light);

  static ThemeData dark() => _theme(darkScheme, PozzoStatusColors.dark);

  static TextStyle _style(FontWeight weight, double size, double lineHeight) =>
      TextStyle(fontFamily: _fontFamily, fontWeight: weight, fontSize: size, height: lineHeight / size);

  /// Sizes and line heights read from the text styles of the design file.
  static final TextTheme _textTheme = TextTheme(
    displayLarge: _style(FontWeight.w800, 56, 64),
    displayMedium: _style(FontWeight.w800, 40, 48),
    displaySmall: _style(FontWeight.w700, 36, 45),
    headlineLarge: _style(FontWeight.w700, 32, 40),
    headlineMedium: _style(FontWeight.w700, 28, 36),
    headlineSmall: _style(FontWeight.w700, 24, 32),
    titleLarge: _style(FontWeight.w600, 22, 28),
    titleMedium: _style(FontWeight.w600, 16, 24),
    titleSmall: _style(FontWeight.w600, 14, 20),
    bodyLarge: _style(FontWeight.w400, 16, 24),
    bodyMedium: _style(FontWeight.w400, 14, 20),
    bodySmall: _style(FontWeight.w400, 12, 16),
    labelLarge: _style(FontWeight.w600, 14, 20),
    labelMedium: _style(FontWeight.w600, 12, 16),
    labelSmall: _style(FontWeight.w500, 11, 16),
  );

  static ThemeData _theme(ColorScheme scheme, PozzoStatusColors status) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        fontFamily: _fontFamily,
        textTheme: _textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
        scaffoldBackgroundColor: scheme.surface,
        extensions: [status],
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: _textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        ),
        // Corner radii of the style guide: 4, 8, 12, 16 and 28, plus pill for buttons and chips.
        cardTheme: CardThemeData(
          elevation: 0,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationThemeData(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.outline),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: const StadiumBorder(),
            foregroundColor: scheme.primary,
            side: BorderSide(color: scheme.outline),
            textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: scheme.surfaceContainer,
          indicatorColor: scheme.primaryContainer,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
}

/// Colors of the states that Material 3 does not have: a validated contribution (success) and one
/// that is late or waiting (warning).
class PozzoStatusColors extends ThemeExtension<PozzoStatusColors> {
  const PozzoStatusColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warningContainer;
  final Color onWarningContainer;

  static const light = PozzoStatusColors(
    success: Color(0xFF426900),
    successContainer: Color(0xFFC2F280),
    onSuccessContainer: Color(0xFF112000),
    warningContainer: Color(0xFFFFDBC8),
    onWarningContainer: Color(0xFF321300),
  );

  static const dark = PozzoStatusColors(
    success: Color(0xFFA7D567),
    successContainer: Color(0xFF314F00),
    onSuccessContainer: Color(0xFFC2F280),
    warningContainer: Color(0xFF743400),
    onWarningContainer: Color(0xFFFFDBC8),
  );

  /// The status colors of the theme in [context].
  static PozzoStatusColors of(BuildContext context) =>
      Theme.of(context).extension<PozzoStatusColors>() ?? light;

  @override
  PozzoStatusColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warningContainer,
    Color? onWarningContainer,
  }) {
    return PozzoStatusColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    );
  }

  @override
  PozzoStatusColors lerp(PozzoStatusColors? other, double t) {
    if (other == null) return this;
    return PozzoStatusColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
    );
  }
}
