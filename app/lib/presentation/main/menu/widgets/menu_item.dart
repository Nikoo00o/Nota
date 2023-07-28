import 'package:app/domain/entities/favourites.dart';
import 'package:app/presentation/main/menu/menu_bloc.dart';
import 'package:app/presentation/main/menu/menu_event.dart';
import 'package:app/presentation/main/menu/menu_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/utils/logger/logger.dart';

final class MenuItem extends BlocPageChild<MenuBloc, MenuState> {
  /// This is also used to identify the current page of the menu and it is also used to return the fitting icon internally!
  final String pageTitleKey;
  final List<String>? pageTitleKeyParams;
  final double iconSize;

  /// this is used for the custom user menu entries to store the [Favourite] object used for identification!
  final Object? additionalData;

  const MenuItem({
    required this.pageTitleKey,
    this.pageTitleKeyParams,
    this.iconSize = 30,
    this.additionalData,
  });

  factory MenuItem.fromFavourite(Favourite favourite) {
    return MenuItem(
      pageTitleKey: "empty.param.1",
      pageTitleKeyParams: <String>[favourite.name],
      additionalData: favourite,
    );
  }

  @override
  Widget buildWithState(BuildContext context, MenuState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
        tileColor: _isCurrentPage(state) ? colorSecondaryContainer(context) : null,
        leading: _getIconForPageTitleKey() != null
            ? Icon(
                _getIconForPageTitleKey(),
                size: iconSize,
              )
            : null,
        minLeadingWidth: iconSize,
        title: Text(translate(context, pageTitleKey, keyParams: pageTitleKeyParams)),
        onTap: () {
          currentBloc(context).add(MenuItemClicked(
            targetPageTranslationKey: pageTitleKey,
            targetPageTranslationKeyParams: pageTitleKeyParams,
            additionalData: additionalData,
          ));
        },
      ),
    );
  }

  // todo: important: this does not show the custom user entries highlighted
  bool _isCurrentPage(MenuState state) {
    return state is MenuStateInitialised &&
        state.currentPageTranslationKey == pageTitleKey &&
        state.currentPageTranslationKeyParams == pageTitleKeyParams;
  }

  IconData? _getIconForPageTitleKey() {
    //todo: add all icons for all menu entries
    switch (pageTitleKey) {
      case "empty.param.1":
        return _getCustomUserIcon();

      case "menu.lock.screen.title":
        return Icons.lock;
      case "menu.logout.title":
        return Icons.logout;
      case "page.settings.title":
        return Icons.settings;
      case "menu.about":
        return Icons.info;
      case "menu.close":
        return Icons.close;
      case "page.logs.title":
        return Icons.storage;

      case "page.dialog.test.title":
        return Icons.question_answer;
      case "page.material.color.test.title":
        return Icons.color_lens_outlined;
      case "page.splash.screen.test.title":
        return Icons.crop_portrait;

      case "notes.root":
        return Icons.folder;
      case "notes.recent":
        return Icons.folder;

      default:
        return null;
    }
  }

  /// user generated menu entries that do not have a translation key
  IconData? _getCustomUserIcon() {
    if (additionalData is NoteFavourite) {
      return Icons.sticky_note_2_outlined;
    } else if (additionalData is FolderFavourite) {
      return Icons.folder;
    }

    return null;
  }
}
