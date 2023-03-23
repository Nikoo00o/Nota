import 'package:app/presentation/main/app/widgets/custom_app_localizations.dart';
import 'package:flutter/material.dart';

abstract class WidgetBase extends StatelessWidget {
  const WidgetBase({super.key});

  /// Translates a translation [key] for the current locale.
  ///
  /// Placeholders are replaced with [keyParams].
  String translate(BuildContext context, String key, {List<String>? keyParams}) {
    return CustomAppLocalizations.of(context)?.translate(key, keyParams: keyParams) ?? "";
  }

  /// Returns the theme data. The [ThemeData.colorScheme] contains the colors used inside of the app.
  ThemeData theme(BuildContext context) => Theme.of(context);

  /// This is the same as [colorBackground]
  Color colorScaffoldBackground(BuildContext context) => theme(context).scaffoldBackgroundColor;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorPrimary(BuildContext context) => theme(context).colorScheme.primary;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOnPrimary(BuildContext context) => theme(context).colorScheme.onPrimary;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorPrimaryContainer(BuildContext context) => theme(context).colorScheme.primaryContainer;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOnPrimaryContainer(BuildContext context) => theme(context).colorScheme.onPrimaryContainer;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorSecondary(BuildContext context) => theme(context).colorScheme.secondary;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOnSecondary(BuildContext context) => theme(context).colorScheme.onSecondary;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorSecondaryContainer(BuildContext context) => theme(context).colorScheme.secondaryContainer;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOnSecondaryContainer(BuildContext context) => theme(context).colorScheme.onSecondaryContainer;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorTertiary(BuildContext context) => theme(context).colorScheme.tertiary;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOnTertiary(BuildContext context) => theme(context).colorScheme.onTertiary;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorTertiaryContainer(BuildContext context) => theme(context).colorScheme.tertiaryContainer;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOnTertiaryContainer(BuildContext context) => theme(context).colorScheme.onTertiaryContainer;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorSurface(BuildContext context) => theme(context).colorScheme.surface;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOnSurface(BuildContext context) => theme(context).colorScheme.onSurface;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorSurfaceVariant(BuildContext context) => theme(context).colorScheme.surfaceVariant;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOnSurfaceVariant(BuildContext context) => theme(context).colorScheme.onSurfaceVariant;

  /// Same as [colorSurface]
  Color colorBackground(BuildContext context) => theme(context).colorScheme.background;

  /// Same as [colorOnSurface]
  Color colorOnBackground(BuildContext context) => theme(context).colorScheme.onBackground;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorError(BuildContext context) => theme(context).colorScheme.error;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOnError(BuildContext context) => theme(context).colorScheme.onError;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorErrorContainer(BuildContext context) => theme(context).colorScheme.errorContainer;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOnErrorContainer(BuildContext context) => theme(context).colorScheme.onErrorContainer;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOutline(BuildContext context) => theme(context).colorScheme.outline;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOutlineVariant(BuildContext context) => theme(context).colorScheme.outlineVariant;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorShadow(BuildContext context) => theme(context).colorScheme.shadow;

  /// Same as [colorShadow]
  Color colorScrim(BuildContext context) => theme(context).colorScheme.scrim;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorSurfaceTint(BuildContext context) => theme(context).colorScheme.shadow;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorInverseSurface(BuildContext context) => theme(context).colorScheme.inverseSurface;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOnInverseSurface(BuildContext context) => theme(context).colorScheme.onInverseSurface;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorInversePrimary(BuildContext context) => theme(context).colorScheme.inversePrimary;

  /// Returns the disabled color of [ThemeData].
  Color colorDisabled(BuildContext context) => theme(context).disabledColor;

  /// Helper method for text styles
  TextStyle _textParams(TextStyle? input) => TextStyle(
      fontSize: input?.fontSize,
      fontWeight: input?.fontWeight,
      letterSpacing: input?.letterSpacing,
      wordSpacing: input?.wordSpacing,
      height: input?.height,
      textBaseline: input?.textBaseline,
      leadingDistribution: input?.leadingDistribution);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textDisplayLarge(BuildContext context) => _textParams(theme(context).textTheme.displayLarge);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textDisplayMedium(BuildContext context) => _textParams(theme(context).textTheme.displayMedium);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textDisplaySmall(BuildContext context) => _textParams(theme(context).textTheme.displaySmall);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textHeadlineLarge(BuildContext context) => _textParams(theme(context).textTheme.headlineLarge);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textHeadlineMedium(BuildContext context) => _textParams(theme(context).textTheme.headlineMedium);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textHeadlineSmall(BuildContext context) => _textParams(theme(context).textTheme.headlineSmall);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textTitleLarge(BuildContext context) => _textParams(theme(context).textTheme.titleLarge);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textTitleMedium(BuildContext context) => _textParams(theme(context).textTheme.titleMedium);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textTitleSmall(BuildContext context) => _textParams(theme(context).textTheme.titleSmall);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textLabelLarge(BuildContext context) => _textParams(theme(context).textTheme.labelLarge);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textLabelMedium(BuildContext context) => _textParams(theme(context).textTheme.labelMedium);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textLabelSmall(BuildContext context) => _textParams(theme(context).textTheme.labelSmall);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textBodyLarge(BuildContext context) => _textParams(theme(context).textTheme.bodyLarge);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textBodyMedium(BuildContext context) => _textParams(theme(context).textTheme.bodyMedium);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textBodySmall(BuildContext context) => _textParams(theme(context).textTheme.bodySmall);

  /// Returns if the current theme is dark
  bool isDarkTheme(BuildContext context) => theme(context).brightness == Brightness.dark;
}
