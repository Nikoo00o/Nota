import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';

base class MenuState extends PageState {
  const MenuState([super.properties = const <String, Object?>{}]);
}

final class MenuStateInitialised extends MenuState {
  final String? username;
  final String currentPageTranslationKey;
  final List<String>? currentPageTranslationKeyParams;
  final bool showDeveloperOptions;
  final List<TranslationString> topLevelFolders;

  MenuStateInitialised({
    required this.username,
    required this.currentPageTranslationKey,
    this.currentPageTranslationKeyParams,
    required this.showDeveloperOptions,
    required this.topLevelFolders,
  }) : super(<String, Object?>{
          "username": username,
          "currentPageTranslationKey": currentPageTranslationKey,
          "currentPageTranslationKeyParams": currentPageTranslationKeyParams,
          "showDeveloperOptions": showDeveloperOptions,
          "topLevelFolders": topLevelFolders,
        });
}
