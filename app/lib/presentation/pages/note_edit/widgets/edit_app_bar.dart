import 'package:app/core/enums/custom_icon_button_type.dart';
import 'package:app/presentation/pages/note_edit/note_edit_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/custom_icon_button.dart';
import 'package:flutter/material.dart';

class EditAppBar extends BlocPageChild<NoteEditBloc, NoteEditState> {
  const EditAppBar();

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
              onChanged: (String _) => currentBloc(context).add(const NoteEditUpdatedState(didSearchChange: true)),
              decoration: InputDecoration(
                hintText: translate(context, "note.selection.search"),
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 12),
              ),
            ),
          ),
        ),
        partWithState,
        const SizedBox(width: 16),
        CustomIconButton(
          icon: Icons.save,
          tooltipKey: "save",
          size: 20,
          buttonType: CustomIconButtonType.FILLED,
          onPressed: () => currentBloc(context).add(const NoteEditInputSaved()),
        ),
      ],
    );
  }

  @override
  Widget buildWithState(BuildContext context, NoteEditState state) {
    if (state is NoteEditStateInitialised) {
      final bool enabled = state.searchPositionSize != "0";
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 32,
                height: 32,
                child: CustomIconButton(
                  padding: EdgeInsets.zero,
                  icon: Icons.arrow_upward,
                  tooltipKey: "note.edit.search.up",
                  size: 20,
                  enabled: enabled,
                  buttonType: CustomIconButtonType.DEFAULT,
                  onPressed: () => currentBloc(context).add(const NoteEditSearchStepped(forward: false)),
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: CustomIconButton(
                  padding: EdgeInsets.zero,
                  icon: Icons.arrow_downward,
                  tooltipKey: "note.edit.search.down",
                  size: 20,
                  enabled: enabled,
                  buttonType: CustomIconButtonType.DEFAULT,
                  onPressed: () => currentBloc(context).add(const NoteEditSearchStepped(forward: true)),
                ),
              ),
            ],
          ),
          Text(
            translate(
              context,
              "note.edit.search.counter",
              keyParams: <String>[state.currentSearchPosition, state.searchPositionSize],
            ),
            style: textLabelSmall(context).copyWith(color: enabled ? null : colorDisabled(context)),
          ),
        ],
      );
    }
    return const SizedBox();
  }
}
