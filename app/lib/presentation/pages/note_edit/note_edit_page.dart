import 'package:app/core/enums/event_action.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/pages/note_edit/note_edit_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/pages/note_edit/widgets/edit_bottom_bar.dart';
import 'package:app/presentation/pages/note_edit/widgets/edit_popup_menu.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/custom_outlined_button.dart';
import 'package:flutter/material.dart';

class NoteEditPage extends BlocPage<NoteEditBloc, NoteEditState> {
  const NoteEditPage() : super(pagePadding: EdgeInsets.zero);

  @override
  NoteEditBloc createBloc(BuildContext context) {
    return sl<NoteEditBloc>()..add(const NoteEditInitialised());
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Scrollbar(child: bodyWithState);
  }

  @override
  Widget buildBodyWithState(BuildContext context, NoteEditState state) {
    if (state is NoteEditStateInitialised) {
      return CustomScrollView(
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Scrollbar(
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: translate(context, "note.edit.input.text"),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                ),
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                minLines: null,
                maxLines: null,
                expands: true,
                style: textBodyLarge(context),
                controller: currentBloc(context).inputController,
                focusNode: currentBloc(context).inputFocusNode,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) => createAppBarWithState(context);

  @override
  PreferredSizeWidget buildAppBarWithState(BuildContext context, NoteEditState state) {
    if (state is NoteEditStateInitialised) {
      if (state.isInputFocused) {
        return _buildEditAppBar(context, state);
      } else {
        return _buildNoEditAppBar(context, state);
      }
    }
    return AppBar(); // use empty app bar at first, so that the element gets cached for performance
  }

  PreferredSizeWidget _buildNoEditAppBar(BuildContext context, NoteEditStateInitialised state) {
    final TranslationString translation = StructureItem.getTranslationStringForStructureItem(state.currentNote);
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: translate(context, "back"),
        onPressed: () => currentBloc(context).add(const NoteEditNavigatedBack()),
      ),
      title: Text(translate(context, translation.translationKey, keyParams: translation.translationKeyParams)),
      centerTitle: false,
      actions: const <Widget>[
        EditPopupMenu(),
      ],
    );
  }

  PreferredSizeWidget _buildEditAppBar(BuildContext context, NoteEditStateInitialised state) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: translate(context, "back"),
        onPressed: () => currentBloc(context).add(const NoteEditNavigatedBack()),
      ),
      title: Row(
        children: <Widget>[
          TextButton(
            onPressed: () => currentBloc(context).add(const NoteEditInputStatusChanged(action: EventAction.CONFIRMED)),
            child: Text(
              translate(context, "save"),
              style: textTitleLarge(context),
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: const <Widget>[
        EditPopupMenu(),
      ],
    );

    //todo: add other widgets
  }

  @override
  Widget buildBottomBar(BuildContext context) => const EditBottomBar();

  @override
  Future<bool> customBackNavigation(BuildContext context) async {
    currentBloc(context).add(const NoteEditNavigatedBack());
    return false;
  }

  @override
  String get pageName => "note edit";
}
