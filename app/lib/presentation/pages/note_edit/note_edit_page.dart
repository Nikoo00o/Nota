import 'package:app/core/enums/event_action.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/pages/note_edit/note_edit_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_event.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/pages/note_edit/widgets/edit_app_bar.dart';
import 'package:app/presentation/pages/note_edit/widgets/edit_bottom_bar.dart';
import 'package:app/presentation/pages/note_edit/widgets/edit_popup_menu.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/life_cycle_callback.dart';
import 'package:flutter/material.dart';

class NoteEditPage extends BlocPage<NoteEditBloc, NoteEditState> {
  const NoteEditPage() : super(pagePadding: EdgeInsets.zero);

  @override
  NoteEditBloc createBloc(BuildContext context) {
    return sl<NoteEditBloc>()..add(const NoteEditInitialised());
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return LifeCycleCallback(
      onPause: () => currentBloc(context).add(const NoteEditAppPaused()),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: true,
            child: Scrollbar(
              controller: currentBloc(context).scrollController,
              child: createBlocSelector<bool>(
                selector: (NoteEditState state) => state is NoteEditStateInitialised,
                builder: _buildEditField,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(BuildContext context, bool isInitialized) {
    if (isInitialized) {
      return TextField(
        scrollController: currentBloc(context).scrollController,
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
        focusNode: currentBloc(context).inputFocus,
        onChanged: (String _) => currentBloc(context).add(const NoteEditUpdatedState(didSearchChange: true)),
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
      child: createBlocSelector<bool>(
        selector: (NoteEditState state) => state is NoteEditStateInitialised,
        builder: (BuildContext context, bool isInitialized) {
          if (isInitialized) {
            return AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: translate(context, "back"),
                onPressed: () => currentBloc(context).add(const NoteEditNavigatedBack()),
              ),
              title: _buildAppBarTitle(context),
              centerTitle: false,
              actions: const <Widget>[
                EditPopupMenu(),
              ],
            );
          } else {
            return AppBar(); // use empty app bar at first, so that the element gets cached for performance
          }
        },
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context) {
    return createBlocBuilder(builder: (BuildContext context, NoteEditState state) {
      final NoteEditStateInitialised initState = state as NoteEditStateInitialised; // always true
      if (initState.isEditing) {
        return const EditAppBar();
      } else {
        final TranslationString translation = StructureItem.getTranslationStringForStructureItem(initState.currentNote);
        return Text(
          translate(context, translation.translationKey, keyParams: translation.translationKeyParams),
          style: textTitleLarge(context).copyWith(fontWeight: FontWeight.bold),
        );
      }
    });
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
