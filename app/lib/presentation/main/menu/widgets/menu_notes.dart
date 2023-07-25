import 'package:app/domain/entities/favourites.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/menu/menu_bloc.dart';
import 'package:app/presentation/main/menu/menu_state.dart';
import 'package:app/presentation/main/menu/widgets/menu_item.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

final class MenuNotes extends BlocPageChild<MenuBloc, MenuState> {
  const MenuNotes();

  @override
  Widget buildWithState(BuildContext context, MenuState state) {
    if (state is MenuStateInitialised) {
      // adding together top level folders and the custom user menu entries
      final List<Widget> widgets =
          state.topLevelFolders.map((TranslationString name) => MenuItem(pageTitleKey: name.translationKey)).toList();
      widgets.addAll(state.userMenuEntries.favourites.map((Favourite fav) => MenuItem.fromFavourite(fav)).toList());
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    }
    return const SizedBox();
  }

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
          child: Text(translate(context, "menu.notes.label"), style: textTitleMedium(context)),
        ),
        partWithState,
      ],
    );
  }
}
