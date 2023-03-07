import 'dart:math';

import 'package:flutter/material.dart';

/// A utility helper class to create a theme for the app.
///
/// Just pick your base material colors which will then be used to generate the [ColorScheme] of the [ThemeData].
/// For Reference: https://m3.material.io/styles/color/the-color-system/tokens#69ad654e-ad14-4757-a67d-5a001f3a7605
///
/// The generated theme will be provided inside of [getTheme].
class AppTheme {
  /// Returns a dark, or light theme with the defined colors!
  static ThemeData newTheme({required bool darkTheme}) {
    // complementary double split colors
    return AppTheme(
      brightness: darkTheme ? Brightness.dark : Brightness.light,
      basePrimaryColor: const Color(0xff0004EB),
      baseSecondaryColor: const Color(0xff0C85EB),
      baseTertiaryColor: const Color(0xff810CEB),
      baseNeutralColor: const Color(0xff878787),
      baseErrorColor: Colors.red[800]!,
    ).getTheme();
  }

  /// if a dark, or light theme should be created from the colors.
  final Brightness brightness;

  /// Used for all most important key components across the UI (FAB, tint of elevated surface, etc).
  ///
  /// In addition to the color "primary", you can also access "onPrimary" for text on a primary background color. And the
  /// same pair is provided an additional time with "primaryContainer" with a different color tone for UI elements needing
  /// less emphasis.
  ///
  /// "primaryContainer" will be brighter than the "primary" color inside of a light theme and darker inside of  a dark
  /// theme. This of course also applies to the other colors as well.
  final Color basePrimaryColor;

  /// Used for less prominent components in the UI (filter chips).
  final Color baseSecondaryColor;

  /// Used as a contrast to balance primary and secondary colors, or bring attention to an element.
  final Color baseTertiaryColor;

  /// Used for the surface and background (mostly black, or white).
  final Color baseNeutralColor;

  /// If this is null, then the [baseNeutralColor] will be used instead.
  final Color? baseNeutralVariantColor;

  /// Used for errors (mostly some shade of red)
  final Color baseErrorColor;

  /// Depending on the [brightness] either a dark, or light theme will be created with the following material key colors.
  /// The individual colors will be set after converting the colors into material colors from the following schemes:
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
    return ThemeData(colorScheme: getColorScheme());
  }

  /// Returns the parsed [ColorScheme] from the base material colors.
  ColorScheme getColorScheme() {
    final bool isDark = brightness == Brightness.dark;
    final MaterialColor primary = convertColor(basePrimaryColor);
    final MaterialColor secondary = convertColor(baseSecondaryColor);
    final MaterialColor tertiary = convertColor(baseTertiaryColor);
    final MaterialColor neutral = convertColor(baseNeutralColor);
    final MaterialColor neutralVariant = convertColor(baseNeutralVariantColor ?? baseNeutralColor);
    final MaterialColor error = convertColor(baseErrorColor);

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
  static MaterialColor convertColor(Color color) {
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

  /// makes color brighter
  static int _tint(int value, double factor) => _bounds(value + ((255 - value) * factor).round());

  /// makes color darker
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
