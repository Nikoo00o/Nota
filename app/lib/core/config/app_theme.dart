import 'dart:math';

import 'package:flutter/material.dart';

/// A utility helper class to create a theme for the app.
///
/// Just pick your base material colors which will then be used to generate the [ColorScheme] of the [ThemeData].
/// For Reference: https://m3.material.io/styles/color/the-color-system/tokens#69ad654e-ad14-4757-a67d-5a001f3a7605
///
/// The generated theme will be provided inside of [getTheme].
class AppTheme {
  /// Returns the theme with the given colors
  static ThemeData get theme {
    return AppTheme(
      brightness: Brightness.dark,
      basePrimaryColor: const Color.fromRGBO(0, 35, 110, 1),
      baseSecondaryColor: const Color.fromRGBO(0, 150, 240, 1),
      baseTertiaryColor: const Color.fromRGBO(80, 220, 160, 1),
      baseNeutralColor: Colors.grey[850]!,
      baseErrorColor: Colors.red[800]!,
    ).getTheme();
  }

  /// if a dark, or light theme should be created from the colors.
  final Brightness brightness;

  final Color basePrimaryColor;

  final Color baseSecondaryColor;

  final Color baseTertiaryColor;

  final Color baseNeutralColor;

  /// If this is null, then the [baseNeutralColor] will be used instead.
  final Color? baseNeutralVariantColor;

  final Color baseErrorColor;

  /// Depending on the [brightness] either a dark, or light theme will be created with the following material key colors.
  /// The individual colours will be set after converting the colors into material colors from the following schemes:
  /// https://m3.material.io/styles/color/the-color-system/tokens#7961fcaf-1342-4fea-a613-b87ddd4434ff
  const AppTheme({
    required this.brightness,
    required this.basePrimaryColor,
    required this.baseSecondaryColor,
    required this.baseTertiaryColor,
    required this.baseNeutralColor,
    this.baseNeutralVariantColor,
    required this.baseErrorColor,
  });

  /// Returns the theme data for this theme with the generated [ColorScheme].
  ThemeData getTheme() {
    return ThemeData(colorScheme: _getColorScheme());
  }

  ColorScheme _getColorScheme() {
    final bool isDark = brightness == Brightness.dark;
    final MaterialColor primary = convertColour(basePrimaryColor);

    final MaterialColor secondary = convertColour(baseSecondaryColor);
    final MaterialColor tertiary = convertColour(baseTertiaryColor);
    final MaterialColor neutral = convertColour(baseNeutralColor);
    final MaterialColor neutralVariant = convertColour(baseNeutralVariantColor ?? baseNeutralColor);
    final MaterialColor error = convertColour(baseErrorColor);

    if (isDark) {
      return ColorScheme(
        primary: primary.mColorTone(80)!,
        onPrimary: primary.mColorTone(20)!,
        primaryContainer: primary.mColorTone(30)!,
        onPrimaryContainer: primary.mColorTone(90)!,
        secondary: secondary.mColorTone(80)!,
        onSecondary: secondary.mColorTone(20)!,
        secondaryContainer: secondary.mColorTone(30)!,
        onSecondaryContainer: secondary.mColorTone(90)!,
        tertiary: tertiary.mColorTone(80)!,
        onTertiary: tertiary.mColorTone(20)!,
        tertiaryContainer: tertiary.mColorTone(30)!,
        onTertiaryContainer: tertiary.mColorTone(90)!,
        background: neutral.mColorTone(10)!,
        onBackground: neutral.mColorTone(90)!,
        surface: neutral.mColorTone(10)!,
        onSurface: neutral.mColorTone(90)!,
        surfaceVariant: neutralVariant.mColorTone(30)!,
        onSurfaceVariant: neutralVariant.mColorTone(80)!,
        outline: neutralVariant.mColorTone(60)!,
        outlineVariant: neutralVariant.mColorTone(60)!,
        error: error.mColorTone(80)!,
        onError: error.mColorTone(20)!,
        errorContainer: error.mColorTone(30)!,
        onErrorContainer: error.mColorTone(90)!,
        brightness: brightness,
      );
    } else {
      return ColorScheme(
        primary: primary.mColorTone(40)!,
        onPrimary: primary.mColorTone(100)!,
        primaryContainer: primary.mColorTone(90)!,
        onPrimaryContainer: primary.mColorTone(10)!,
        secondary: secondary.mColorTone(40)!,
        onSecondary: secondary.mColorTone(100)!,
        secondaryContainer: secondary.mColorTone(90)!,
        onSecondaryContainer: secondary.mColorTone(10)!,
        tertiary: tertiary.mColorTone(40)!,
        onTertiary: tertiary.mColorTone(100)!,
        tertiaryContainer: tertiary.mColorTone(90)!,
        onTertiaryContainer: tertiary.mColorTone(10)!,
        background: neutral.mColorTone(99)!,
        onBackground: neutral.mColorTone(10)!,
        surface: neutral.mColorTone(99)!,
        onSurface: neutral.mColorTone(10)!,
        surfaceVariant: neutralVariant.mColorTone(90)!,
        onSurfaceVariant: neutralVariant.mColorTone(30)!,
        outline: neutralVariant.mColorTone(50)!,
        outlineVariant: neutralVariant.mColorTone(50)!,
        error: error.mColorTone(40)!,
        onError: error.mColorTone(100)!,
        errorContainer: error.mColorTone(90)!,
        onErrorContainer: error.mColorTone(10)!,
        brightness: brightness,
      );
    }
  }

  /// The returned material color also has [0] set to white and [1000] set to black and of course [500] set to the color
  /// itself. This also contains some additional tints and shades.
  ///
  /// [900] is the material color tone [10].
  /// [50] is the material color tone [95].
  /// [10] is the material color tone [99].
  static MaterialColor convertColour(Color color) {
    final Map<int, Color> colorMap = <int, Color>{
      0: _tintColor(color, 1.0),
      10: _tintColor(color, 0.98),
      50: _tintColor(color, 0.9),
      100: _tintColor(color, 0.8),
      200: _tintColor(color, 0.6),
      300: _tintColor(color, 0.4),
      400: _tintColor(color, 0.2),
      500: color,
      600: _shadeColor(color, 0.2),
      700: _shadeColor(color, 0.4),
      800: _shadeColor(color, 0.6),
      900: _shadeColor(color, 0.8),
      1000: _shadeColor(color, 1.0),
    };
    return MaterialColor(color.value, colorMap);
  }

  static Color _tintColor(Color color, double factor) =>
      Color.fromRGBO(_tint(color.red, factor), _tint(color.green, factor), _tint(color.blue, factor), 1);

  static Color _shadeColor(Color color, double factor) =>
      Color.fromRGBO(_shade(color.red, factor), _shade(color.green, factor), _shade(color.blue, factor), 1);

  /// makes colour brighter
  static int _tint(int value, double factor) => _bounds(value + ((255 - value) * factor).round());

  /// makes colour darker
  static int _shade(int value, double factor) => _bounds(value - (value * factor).round());

  /// between 0 and 255 .
  static int _bounds(int value) => max(0, min(255, value));
}

extension on MaterialColor {
  /// Returns the material color tone from 0 to 100 of this color by using the swatch shades.
  Color? mColorTone(int tone) {
    assert(tone >= 0 && tone <= 100, "color tone must be in the inclusive range of 0 to 100!");
    return this[1000 - tone * 10];
  }
}
