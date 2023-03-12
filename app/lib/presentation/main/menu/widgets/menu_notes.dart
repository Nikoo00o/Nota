import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/menu/menu_bloc.dart';
import 'package:app/presentation/main/menu/menu_state.dart';
import 'package:app/presentation/main/menu/widgets/menu_item.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

class MenuNotes extends BlocPageChild<MenuBloc, MenuState> {
  const MenuNotes();

  @override
  Widget buildWithState(BuildContext context, MenuState state) {
    if (state is MenuStateInitialised) {
      //todo: also handle user custom menu favourites by also checking the keyparams and not only the translation key
      final List<Widget> widgets =
          state.topLevelFolders.map((TranslationString name) => MenuItem(pageTitleKey: name.translationKey)).toList();
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
