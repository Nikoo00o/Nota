import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

class SelectionSearchBar extends BlocPageChild<NoteSelectionBloc, NoteSelectionState> {
  const SelectionSearchBar();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return Row(
      children: <Widget>[
        Flexible(
          child: Container(
            height: 34.0,
            decoration: BoxDecoration(
              color: colorPrimary(context).withOpacity(0.15),
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.only(right: 10),
            child: TextField(
              focusNode: currentBloc(context).searchFocus,
              controller: currentBloc(context).searchController,
              onChanged: (String _) => currentBloc(context).add(const NoteSelectionUpdatedState()),
              decoration: InputDecoration(
                hintText: translate(context, "note.selection.search.name"),
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        SizedBox(
          width: 45,
          height: 40,
          child: TextButton(
            onPressed: () => currentBloc(context).add(const NoteSelectionFocusSearch(focus: false)),
            child: Text(translate(context, "ok")),
          ),
        ),
        const SizedBox(width: 14),
      ],
    );
  }
}
