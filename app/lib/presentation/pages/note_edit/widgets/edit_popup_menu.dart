import 'package:app/presentation/pages/note_edit/note_edit_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

class EditPopupMenu extends BlocPageChild<NoteEditBloc, NoteEditState> {
  const EditPopupMenu();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return partWithState;
  }

  @override
  Widget buildWithState(BuildContext context, NoteEditState state) {
    if (state is NoteEditStateInitialised) {
      return PopupMenuButton<int>(
        onSelected: (int value) => currentBloc(context).add(NoteEditDropDownMenuSelected(index: value)),
        itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
          PopupMenuItem<int>(value: 0, child: Text(translate(context, "note.selection.rename"))),
          PopupMenuItem<int>(value: 1, child: Text(translate(context, "note.selection.move"))),
          PopupMenuItem<int>(value: 2, child: Text(translate(context, "note.selection.delete"))),
          PopupMenuItem<int>(value: 3, child: Text(translate(context, "note.selection.search"))),
        ],
      );
    }
    return const SizedBox();
  }
}
