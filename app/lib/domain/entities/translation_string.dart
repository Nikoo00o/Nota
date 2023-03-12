import 'package:shared/core/utils/immutable_equatable.dart';

/// Helper class that contains the [translationKey] with the [translationKeyParams] which will be translated.
class TranslationString extends ImmutableEquatable {
  final String translationKey;
  final List<String>? translationKeyParams;

  TranslationString(
    this.translationKey, {
    this.translationKeyParams,
  }) : super(<String, Object?>{
          "translationKey": translationKey,
          "translationKeyParams": translationKeyParams,
        });
}

// todo: in the future migrate everything to use these translation strings!!!