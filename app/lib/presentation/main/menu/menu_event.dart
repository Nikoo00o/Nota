import 'package:app/domain/entities/favourites.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';

sealed class MenuEvent extends PageEvent {
  const MenuEvent();
}

final class MenuInitialised extends MenuEvent {
  final String currentPageTranslationKey;
  final List<String>? currentPageTranslationKeyParams;

  const MenuInitialised({required this.currentPageTranslationKey, this.currentPageTranslationKeyParams});
}

final class MenuItemClicked extends MenuEvent {
  final String targetPageTranslationKey;
  final List<String>? targetPageTranslationKeyParams;
  /// this is used for the custom user menu entries to store the [Favourite] object used for identification!
  final Object? additionalData;

  const MenuItemClicked({
    required this.targetPageTranslationKey,
    this.targetPageTranslationKeyParams,
    this.additionalData,
  });
}

final class MenuUserProfileClicked extends MenuEvent {}
