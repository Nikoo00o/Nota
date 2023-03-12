import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/presentation/main/app/app_bloc.dart';
import 'package:flutter/services.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// A Service Used for translating strings with translation keys.
///
/// The translated values are inside of json files inside of the "assets" folder as a key : value map which can also
/// contain placeholders in the format of "{0}", "{1}", etc which will be replaced by additional string params.
class TranslationService {
  Map<String, String>? _keys;

  final AppSettingsRepository appSettingsRepository;

  Locale? _locale;

  TranslationService({required this.appSettingsRepository});

  /// The path to the "assets/" dir
  static String get _basePath => "assets${Platform.pathSeparator}";

  /// must be called at the beginning of the app to load the translated values.
  Future<void> init() async {
    final Locale locale = await appSettingsRepository.getCurrentLocale();
    if (locale != _locale) {
      _locale = locale;
      final String jsonString = await rootBundle.loadString("$_basePath${locale.languageCode}.json");

      final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      _keys = jsonMap.map((String key, dynamic value) {
        return MapEntry<String, String>(key, value.toString());
      });
      Logger.debug("Loaded ${_keys?.length ?? 0} key-value-pairs for the locale $locale");
    }
  }

  /// Translates a [key] to a value of the map and replaces the placeholders with the optional [keyParams]..
  ///
  /// If no value was found for the [key], it will return the key itself.
  String translate(String key, {List<String>? keyParams}) {
    if (_keys != null && _keys!.containsKey(key)) {
      String translatedKey = _keys![key]!;
      if (keyParams != null && keyParams.isNotEmpty) {
        for (int i = 0; i < keyParams.length; i++) {
          final String param = keyParams[i];
          final String placeholder = "{$i}";
          if (translatedKey.contains(placeholder)) {
            translatedKey = translatedKey.replaceAll(placeholder, param);
          } else {
            Logger.warn("Could not replace '$placeholder' with '$param' in '$key'");
          }
        }
      }
      return translatedKey;
    }
    Logger.warn("The key to be translated was not found: $key");
    return key;
  }

  /// Returns the current [_locale] if it is not null and was already initialized with [init].
  /// Otherwise this throws a [ClientException] with [ErrorCodes.FILE_NOT_FOUND].
  Locale get currentLocale {
    if (_locale == null) {
      throw const ClientException(message: ErrorCodes.FILE_NOT_FOUND);
    }
    return _locale!;
  }
}
