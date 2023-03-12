import 'package:app/presentation/widgets/base_pages/page_state.dart';

class MenuState extends PageState {
  const MenuState([super.properties = const <String, Object?>{}]);
}

class MenuStateInitialised extends MenuState {
  final String? userName;
  final String currentPageTranslationKey;
  final List<String>? currentPageTranslationKeyParams;
  final bool showDeveloperOptions;

  MenuStateInitialised({
    required this.userName,
    required this.currentPageTranslationKey,
    this.currentPageTranslationKeyParams,
    required this.showDeveloperOptions,
  }) : super(<String, Object?>{
          "userName": userName,
          "currentPageTranslationKey": currentPageTranslationKey,
          "currentPageTranslationKeyParams": currentPageTranslationKeyParams,
          "showDeveloperOptions": showDeveloperOptions,
        });
}
