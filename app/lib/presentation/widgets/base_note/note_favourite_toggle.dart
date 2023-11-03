import 'package:app/presentation/widgets/base_note/base_note_bloc.dart';
import 'package:app/presentation/widgets/base_note/base_note_event.dart';
import 'package:app/presentation/widgets/base_note/base_note_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

final class NoteFavouriteToggle<Bloc extends BaseNoteBloc<State>, State extends BaseNoteState>
    extends BlocPageChild<Bloc, State> {
  const NoteFavouriteToggle();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return partWithState;
  }

  @override
  Widget buildWithState(BuildContext context, State state) {
    if (state.isInitialized) {
      return IconButton(
        color: state.isFavourite ? colorPrimary(context) : null,
        icon: state.isFavourite ? const Icon(Icons.star) : const Icon(Icons.star_outline),
        tooltip: translate(context, "widget.favourite"),
        onPressed: () => currentBloc(context).add(BaseNoteFavouriteChanged(isFavourite: !state.isFavourite)),
      );
    } else {
      return const SizedBox();
    }
  }
}
