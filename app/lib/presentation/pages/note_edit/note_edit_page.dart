import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/pages/note_edit/note_edit_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/custom_icon_button.dart';
import 'package:flutter/material.dart';

class NoteEditPage extends BlocPage<NoteEditBloc, NoteEditState> {
  const NoteEditPage() : super();

  @override
  NoteEditBloc createBloc(BuildContext context) {
    return sl<NoteEditBloc>()..add(const NoteEditInitialised());
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Scrollbar(child: bodyWithState);
  }

  @override
  Widget buildBodyWithState(BuildContext context, NoteEditState state) {
    return Text("todo: implement...");
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) => createAppBarWithState(context);

  @override
  PreferredSizeWidget buildAppBarWithState(BuildContext context, NoteEditState state) {
    if (state is NoteEditStateInitialised) {
      final TranslationString translation = StructureItem.getTranslationStringForStructureItem(state.currentNote);
      return AppBar(
        title: Text(translate(context, translation.translationKey, keyParams: translation.translationKeyParams)),
        centerTitle: false,
        actions: <Widget>[
          PopupMenuButton<int>(
            onSelected: (int value) => currentBloc(context).add(NoteEditDropDownMenuSelected(index: value)),
            itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
              PopupMenuItem<int>(value: 0, child: Text(translate(context, "note.selection.rename"))),
              PopupMenuItem<int>(value: 1, child: Text(translate(context, "note.selection.move"))),
              PopupMenuItem<int>(value: 2, child: Text(translate(context, "note.selection.delete"))),
            ],
          ),
        ],
      );
    }
    return AppBar(); // use empty app bar at first, so that the element gets cached for performance
  }

  @override
  Widget buildBottomBar(BuildContext context) => createBottomBarWithState(context);

  @override
  Widget buildBottomBarWithState(BuildContext context, NoteEditState state) {
    if (state is NoteSelectionStateInitialised) {
      return BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            CustomIconButton(
              icon: Icons.search,
              tooltip: "note.selection.search",
              size: 30,
              onPressed: () {},
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  @override
  Future<bool> customBackNavigation(BuildContext context) async {
    currentBloc(context).add(const NoteEditNavigatedBack());
    return false;
  }

  @override
  String get pageName => "note edit";
}
