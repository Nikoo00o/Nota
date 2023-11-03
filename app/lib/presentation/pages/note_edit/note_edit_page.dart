import 'package:app/core/enums/custom_icon_button_type.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/pages/note_edit/note_edit_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/pages/note_edit/widgets/edit_bottom_bar.dart';
import 'package:app/presentation/pages/note_edit/widgets/edit_search_bar.dart';
import 'package:app/presentation/widgets/base_note/base_note_event.dart';
import 'package:app/presentation/widgets/base_note/base_note_page.dart';
import 'package:app/presentation/widgets/base_note/note_popup_menu.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/custom_icon_button.dart';
import 'package:app/presentation/widgets/life_cycle_callback.dart';
import 'package:flutter/material.dart';

final class NoteEditPage extends BaseNotePage<NoteEditBloc, NoteEditState> {
  const NoteEditPage() : super(pagePadding: EdgeInsets.zero);

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return LifeCycleCallback(
      onPause: () => currentBloc(context).add(const NoteEditAppPaused()),
      child: Scrollbar(
        controller: currentBloc(context).scrollController,
        child: createBlocBuilder(builder: _buildEditField),
      ),
    );
  }

  Widget _buildEditField(BuildContext context, NoteEditState state) {
    if (state.isInitialized) {
      return TextField(
        scrollController: currentBloc(context).scrollController,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: translate(context, "note.edit.input.text"),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        minLines: null,
        maxLines: null,
        expands: true,
        style: textBodyLarge(context),
        controller: currentBloc(context).inputController,
        focusNode: currentBloc(context).inputFocus,
        onChanged: (String _) => currentBloc(context).add(const BaseNoteUpdatedState()),
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return PreferredSize(
      // default size
      preferredSize: const Size.fromHeight(BlocPage.defaultAppBarHeight),
      child: createBlocSelector<StructureItem?>(
        selector: (NoteEditState state) => state.currentItem,
        builder: (BuildContext context, StructureItem? currentItem) {
          if (currentItem == null) {
            return AppBar(); // use empty app bar at first, so that the element gets cached for performance
          } else {
            return createBlocSelector<bool>(
              selector: (NoteEditState state) => state.isEditing,
              builder: (BuildContext context, bool isEditing) {
                if (isEditing) {
                  return AppBar(
                    leading: buildBackButton(context),
                    title: const EditSearchBar(),
                    centerTitle: false,
                    titleSpacing: 8,
                    actions: <Widget>[
                      buildSaveButton(context),
                      const NotePopupMenu<NoteEditBloc, NoteEditState>(),
                    ],
                  );
                } else {
                  return buildTitleAppBar(context, currentItem, withBackButton: true);
                }
              },
            );
          }
        },
      ),
    );
  }

  Widget buildSaveButton(BuildContext context) {
    return CustomIconButton(
      icon: Icons.save,
      tooltipKey: "save",
      size: 20,
      buttonType: CustomIconButtonType.FILLED,
      onPressed: () => currentBloc(context).add(const NoteEditInputSaved()),
    );
  }

  @override
  Widget buildBottomBar(BuildContext context) => const EditBottomBar();

  @override
  String get pageName => "note edit";
}
