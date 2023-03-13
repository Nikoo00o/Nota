import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';

class NoteSelectionPage extends BlocPage<NoteSelectionBloc, NoteSelectionState> {
  const NoteSelectionPage() : super();

  @override
  NoteSelectionBloc createBloc(BuildContext context) {
    return sl<NoteSelectionBloc>()..add(const NoteSelectionInitialised());
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Scrollbar(
      child: SingleChildScrollView(
        child: bodyWithState,
      ),
    );
  }

  @override
  Widget buildBodyWithState(BuildContext context, NoteSelectionState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[],
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) => createAppBarWithState(context);

  @override
  PreferredSizeWidget buildAppBarWithState(BuildContext context, NoteSelectionState state) {
    if (state is NoteSelectionStateInitialised) {
      final TranslationString translation = StructureItem.getTranslationStringForStructureItem(state.currentItem);
      return AppBar(
        title: Text(translate(context, translation.translationKey, keyParams: translation.translationKeyParams)),
        centerTitle: false,
      );
    }
    return AppBar(); // use empty app bar at first, so that the element gets cached for performance
  }

  @override
  Widget? buildMenuDrawer(BuildContext context) => createMenuDrawerWithState(context);

  @override
  Widget buildMenuDrawerWithState(BuildContext context, NoteSelectionState state) {
    // this will only ever show either root, or recent
    if (state is NoteSelectionStateInitialised) {
      final TranslationString translation =
          StructureItem.getTranslationStringForStructureItem(state.currentItem.topMostParent);
      return LoggedInMenu(
        currentPageTranslationKey: translation.translationKey,
        currentPageTranslationKeyParams: translation.translationKeyParams,
      );
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    // important: don't show the menu drawer for move selection
    return buildWithToggleForMenuDrawer(
        context,
        (NoteSelectionState state) =>
            state is NoteSelectionStateInitialised && state.currentItem.topMostParent.topMostParent.isMove == false);
  }

  @override
  String get pageName => "note selection";
}
