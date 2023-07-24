import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

final class SelectionPopupMenu extends BlocPageChild<NoteSelectionBloc, NoteSelectionState> {
  const SelectionPopupMenu();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return partWithState;
  }

  @override
  Widget buildWithState(BuildContext context, NoteSelectionState state) {
    if (state is NoteSelectionStateInitialised) {
      return PopupMenuButton<int>(
        onSelected: (int value) => currentBloc(context).add(NoteSelectionDropDownMenuSelected(index: value)),
        itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
          PopupMenuItem<int>(
            value: 0,
            enabled: state.currentFolder.canBeModified,
            child: Text(translate(context, "note.selection.rename")),
          ),
          PopupMenuItem<int>(
              value: 1, enabled: state.currentFolder.canBeModified, child: Text(translate(context, "note.selection.move"))),
          PopupMenuItem<int>(
              value: 2,
              enabled: state.currentFolder.canBeModified,
              child: Text(translate(context, "note.selection.delete"))),
          PopupMenuItem<int>(
              value: 3,
              enabled: state.currentFolder.topMostParent.isMove == false,
              child: Text(translate(context, "note.selection.extended.search"))),
        ],
      );
    }
    return const SizedBox();
  }
}
