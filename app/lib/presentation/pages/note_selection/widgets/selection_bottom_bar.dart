import 'package:app/core/enums/custom_icon_button_type.dart';
import 'package:app/core/enums/event_action.dart';
import 'package:app/core/enums/search_status.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/custom_icon_button.dart';
import 'package:app/presentation/widgets/custom_outlined_button.dart';
import 'package:app/services/dialog_service.dart';
import 'package:flutter/material.dart';

final class SelectionBottomBar extends BlocPageChild<NoteSelectionBloc, NoteSelectionState> {
  const SelectionBottomBar();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return partWithState;
  }

  @override
  Widget buildWithState(BuildContext context, NoteSelectionState state) {
    if (state is NoteSelectionStateInitialised) {
      if (state.currentFolder.topMostParent.isMove) {
        return _buildMoveBar(context, state);
      } else {
        return _buildCompleteBar(context, state);
      }
    }
    return const SizedBox();
  }

  Widget _buildMoveBar(BuildContext context, NoteSelectionStateInitialised state) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          CustomOutlinedButton(
            onPressed: () => currentBloc(context).add(const NoteSelectionChangedMove(status: EventAction.CANCELLED)),
            textKey: "cancel",
          ),
          FilledButton(
            onPressed: () => currentBloc(context).add(const NoteSelectionChangedMove(status: EventAction.CONFIRMED)),
            child: Text(translate(context, "confirm")),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteBar(BuildContext context, NoteSelectionStateInitialised state) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          CustomIconButton(
            icon: Icons.search,
            tooltipKey: "note.selection.search",
            size: 30,
            buttonType: CustomIconButtonType.OUTLINED,
            onPressed: () => currentBloc(context).add(const NoteSelectionChangeSearch(searchStatus: SearchStatus.DEFAULT)),
          ),
          CustomIconButton(
            icon: Icons.sync,
            tooltipKey: "note.selection.sync",
            size: 30,
            buttonType: CustomIconButtonType.FILLED_TERTIARY,
            onPressed: () => currentBloc(context).add(const NoteSelectionServerSynced()),
          ),
          CustomIconButton(
            enabled: state.currentFolder.isRecent == false,
            icon: Icons.create_new_folder_rounded,
            tooltipKey: state.currentFolder.isRecent ? "available.in.different.view" : "note.selection.create.folder",
            size: 30,
            buttonType: CustomIconButtonType.FILLED_SECONDARY,
            onDisabledPress: () =>
                sl<DialogService>().showInfoDialog(const ShowInfoDialog(descriptionKey: "available.in.different.view")),
            onPressed: () => currentBloc(context).add(const NoteSelectionCreatedItem(isFolder: true)),
          ),
          CustomIconButton(
            icon: Icons.note_add,
            tooltipKey: "note.selection.create.note",
            size: 30,
            buttonType: CustomIconButtonType.FILLED,
            onPressed: () => currentBloc(context).add(const NoteSelectionCreatedItem(isFolder: false)),
          ),
        ],
      ),
    );
  }
}
