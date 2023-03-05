import 'package:app/core/get_it.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/material.dart';

abstract class WidgetBase extends StatelessWidget {
  const WidgetBase({super.key});

  /// returns the theme data
  ThemeData theme(BuildContext context) => Theme.of(context);

  /// Translates a translation [key] for the current locale.
  ///
  /// Placeholders are replaced with [keyParams].
  String translate(String key, {List<String>? keyParams}) {
    return sl<TranslationService>().translate(key, keyParams: keyParams); // direct access, because every widget should
    // not contain a reference to the translation service
  }
}
