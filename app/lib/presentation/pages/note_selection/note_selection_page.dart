import 'dart:async';
import 'package:app/core/enums/search_status.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/pages/note_selection/widgets/current_folder_info.dart';
import 'package:app/presentation/pages/note_selection/widgets/selection_bottom_bar.dart';
import 'package:app/presentation/pages/note_selection/widgets/selection_favourite_toggle.dart';
import 'package:app/presentation/pages/note_selection/widgets/selection_popup_menu.dart';
import 'package:app/presentation/pages/note_selection/widgets/selection_search_bar.dart';
import 'package:app/presentation/pages/note_selection/widgets/structure_item_box.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:flutter/material.dart';

final class NoteSelectionPage extends BlocPage<NoteSelectionBloc, NoteSelectionState> {
  const NoteSelectionPage() : super(pagePadding: const EdgeInsets.fromLTRB(5, 0, 5, 0));

  @override
  NoteSelectionBloc createBloc(BuildContext context) {
    return sl<NoteSelectionBloc>()..add(const NoteSelectionInitialised());
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Scrollbar(controller: currentBloc(context).scrollController, child: bodyWithState);
  }

  @override
  Widget buildBodyWithState(BuildContext context, NoteSelectionState state) {
    if (state is NoteSelectionStateInitialised) {
      return ListView.builder(
        controller: currentBloc(context).scrollController,
        // always one extra item for the info about the current folder
        itemCount: state.currentFolder.amountOfChildren + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return CurrentFolderInfo(folder: state.currentFolder);
          } else {
            final int itemIndex = index - 1; // so of course here the index must be decreased by one
            return StructureItemBox(item: state.currentFolder.getChild(itemIndex), index: itemIndex);
          }
        },
      );
    }
    return const SizedBox();
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) => createAppBarWithState(context);

  @override
  PreferredSizeWidget buildAppBarWithState(BuildContext context, NoteSelectionState state) {
    if (state is NoteSelectionStateInitialised) {
      if (state.searchStatus != SearchStatus.DISABLED) {
        return _buildSearchAppBar(context, state);
      } else {
        return _buildTitleAppBar(context, state);
      }
    }
    return AppBar(); // use empty app bar at first, so that the element gets cached for performance
  }

  PreferredSizeWidget _buildTitleAppBar(BuildContext context, NoteSelectionStateInitialised state) {
    final TranslationString translation = StructureItem.getTranslationStringForStructureItem(state.currentFolder);
    return AppBar(
      title: Text(
        translate(context, translation.translationKey, keyParams: translation.translationKeyParams),
        overflow: TextOverflow.fade,
        style: textTitleLarge(context).copyWith(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      titleSpacing: 8,
      actions: const <Widget>[
        SelectionFavouriteToggle(),
        SelectionPopupMenu(),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar(BuildContext context, NoteSelectionStateInitialised state) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: translate(context, "back"),
        onPressed: () => currentBloc(context).add(const NoteSelectionNavigatedBack(completer: null, ignoreSearch: false)),
      ),
      title: const SelectionSearchBar(),
      centerTitle: false,
    );
  }

  @override
  Widget? buildMenuDrawer(BuildContext context) => createMenuDrawerWithState(context);

  @override
  Widget buildMenuDrawerWithState(BuildContext context, NoteSelectionState state) {
    // this will only ever show either root, or recent as the selected menu entry
    if (state is NoteSelectionStateInitialised) {
      final TranslationString translation =
          StructureItem.getTranslationStringForStructureItem(state.currentFolder.topMostParent);
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
    return buildWithToggleForMenuDrawer(context, _shouldBuildMenuDrawer);
  }

  bool _shouldBuildMenuDrawer(NoteSelectionState state) =>
      state is NoteSelectionStateInitialised && state.currentFolder.topMostParent.topMostParent.isMove == false;

  @override
  Widget buildBottomBar(BuildContext context) => const SelectionBottomBar();

  @override
  Future<bool> customBackNavigation(BuildContext context) async {
    final Completer<bool> completer = Completer<bool>();
    currentBloc(context).add(NoteSelectionNavigatedBack(completer: completer, ignoreSearch: false));
    return completer.future;
  }

  @override
  String get pageName => "note selection";
}
