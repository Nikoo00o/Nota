import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

final class SelectionFavouriteToggle extends BlocPageChild<NoteSelectionBloc, NoteSelectionState> {
  const SelectionFavouriteToggle();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return partWithState;
  }

  @override
  Widget buildWithState(BuildContext context, NoteSelectionState state) {
    if (state is NoteSelectionStateInitialised && state.currentFolder.canBeModified) {
      return IconButton(
        color: state.isFavourite ? colorPrimary(context) : null,
        icon: state.isFavourite ? const Icon(Icons.star) : const Icon(Icons.star_outline),
        tooltip: translate(context, "widget.favourite"),
        onPressed: () => currentBloc(context).add(NoteSelectionChangeFavourite(isFavourite: !state.isFavourite)),
      );
    }
    return const SizedBox();
  }
}
