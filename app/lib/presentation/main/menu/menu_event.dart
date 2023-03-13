import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class MenuEvent extends PageEvent {
  const MenuEvent();
}

class MenuInitialised extends MenuEvent {
  final String currentPageTranslationKey;
  final List<String>? currentPageTranslationKeyParams;

  const MenuInitialised({required this.currentPageTranslationKey, this.currentPageTranslationKeyParams});
}

class MenuItemClicked extends MenuEvent {
  final String targetPageTranslationKey;
  final List<String>? targetPageTranslationKeyParams;

  const MenuItemClicked({required this.targetPageTranslationKey, this.targetPageTranslationKeyParams});
}

class MenuUserProfileClicked extends MenuEvent {}
