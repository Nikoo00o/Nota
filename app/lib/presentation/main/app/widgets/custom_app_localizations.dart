import 'dart:async';
import 'package:app/core/constants/locales.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/material.dart';

class CustomAppLocalizations {
  final TranslationService translationService;

  const CustomAppLocalizations({required this.translationService});

  /// Used for translation
  static CustomAppLocalizations? of(BuildContext context) {
    return Localizations.of<CustomAppLocalizations>(context, CustomAppLocalizations);
  }

  /// delegate translate to translation service
  String translate(String key, {List<String>? keyParams}) {
    return translationService.translate(key, keyParams: keyParams);
  }
}

class CustomAppLocalizationsDelegate extends LocalizationsDelegate<CustomAppLocalizations> {
  final TranslationService translationService;

  const CustomAppLocalizationsDelegate({required this.translationService});

  @override
  bool isSupported(Locale locale) =>
      Locales.supportedLocales.where((Locale other) => other.languageCode == locale.languageCode).isNotEmpty;

  @override
  Future<CustomAppLocalizations> load(Locale locale) async {
    return CustomAppLocalizations(translationService: translationService);
  }

  @override
  bool shouldReload(CustomAppLocalizationsDelegate old) => false;
}
