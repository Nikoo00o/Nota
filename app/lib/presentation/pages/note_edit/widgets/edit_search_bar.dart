import 'package:app/core/enums/custom_icon_button_type.dart';
import 'package:app/presentation/pages/note_edit/note_edit_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/widgets/base_note/base_note_event.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/custom_icon_button.dart';
import 'package:flutter/material.dart';

final class EditSearchBar extends BlocPageChild<NoteEditBloc, NoteEditState> {
  const EditSearchBar();

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
              onChanged: (String _) => currentBloc(context).add(const BaseNoteUpdatedState()),
              decoration: InputDecoration(
                hintText: translate(context, "note.selection.search"),
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 12),
              ),
            ),
          ),
        ),
        _buildTitle(context),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return createBlocSelector<bool>(
      selector: (NoteEditState state) => state.isInitialized,
      builder: (BuildContext context, bool initialised) {
        if (initialised) {
          return createBlocSelector<bool>(
            selector: (NoteEditState state) => state.isInitialized && state.searchPositionSize != "0",
            builder: (BuildContext context, bool enabled) {
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
                  _buildStateCounter(context, enabled),
                ],
              );
            },
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildStateCounter(BuildContext context, bool enabled) {
    return createBlocSelector<String>(
      selector: (NoteEditState state) => state.currentSearchPosition,
      builder: (BuildContext context, String currentSearchPosition) {
        return createBlocSelector<String>(
          selector: (NoteEditState state) => state.searchPositionSize,
          builder: (BuildContext context, String searchPositionSize) {
            return Text(
              translate(
                context,
                "note.edit.search.counter",
                keyParams: <String>[currentSearchPosition, searchPositionSize],
              ),
              style: textLabelSmall(context).copyWith(color: enabled ? null : colorDisabled(context)),
            );
          },
        );
      },
    );
  }
}