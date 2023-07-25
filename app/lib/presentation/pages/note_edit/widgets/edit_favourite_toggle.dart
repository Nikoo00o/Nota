import 'package:app/presentation/pages/note_edit/note_edit_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

final class EditFavouriteToggle extends BlocPageChild<NoteEditBloc, NoteEditState> {
  const EditFavouriteToggle();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return partWithState;
  }

  @override
  Widget buildWithState(BuildContext context, NoteEditState state) {
    if (state is NoteEditStateInitialised) {
      return IconButton(
        color: state.isFavourite ? colorPrimary(context) : null,
        icon: state.isFavourite ? const Icon(Icons.star) : const Icon(Icons.star_outline),
        tooltip: translate(context, "widget.favourite"),
        onPressed: () => currentBloc(context).add(NoteEditChangeFavourite(isFavourite: !state.isFavourite)),
      );
    }
    return const SizedBox();
  }
}
