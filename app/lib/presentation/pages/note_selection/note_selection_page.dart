import 'dart:async';
import 'package:app/core/enums/custom_icon_button_type.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/pages/note_selection/widgets/current_folder_info.dart';
import 'package:app/presentation/pages/note_selection/widgets/structure_item_box.dart';
import 'package:app/presentation/pages/settings/widgets/settings_toggle_option.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/custom_icon_button.dart';
import 'package:flutter/material.dart';

class NoteSelectionPage extends BlocPage<NoteSelectionBloc, NoteSelectionState> {
  const NoteSelectionPage() : super(pagePadding: const EdgeInsets.fromLTRB(5, 0, 5, 0));

  @override
  NoteSelectionBloc createBloc(BuildContext context) {
    return sl<NoteSelectionBloc>()..add(const NoteSelectionInitialised());
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Scrollbar(child: bodyWithState);
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
      final TranslationString translation = StructureItem.getTranslationStringForStructureItem(state.currentFolder);
      return AppBar(
        title: Text(translate(context, translation.translationKey, keyParams: translation.translationKeyParams),
            overflow: TextOverflow.fade),
        centerTitle: false,
        actions: <Widget>[
          PopupMenuButton<int>(
            onSelected: (int value) => currentBloc(context).add(NoteSelectionDropDownMenuSelected(index: value)),
            itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
              PopupMenuItem<int>(value: 0, child: Text(translate(context, "note.selection.rename"))),
              PopupMenuItem<int>(value: 1, child: Text(translate(context, "note.selection.move"))),
              PopupMenuItem<int>(value: 2, child: Text(translate(context, "note.selection.delete"))),
              PopupMenuItem<int>(value: 3, child: Text(translate(context, "note.selection.extended.search"))),
            ],
          ),
        ],
      );
    }
    return AppBar(); // use empty app bar at first, so that the element gets cached for performance
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
  Widget buildBottomBar(BuildContext context) => createBottomBarWithState(context);

  @override
  Widget buildBottomBarWithState(BuildContext context, NoteSelectionState state) {
    //todo: move selection has different bottom bar
    if (state is NoteSelectionStateInitialised) {
      return BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            CustomIconButton(
              icon: Icons.search,
              tooltipKey: "note.selection.search",
              size: 30,
              onPressed: () {},
            ),
            CustomIconButton(
              icon: Icons.sync,
              tooltipKey: "note.selection.sync",
              size: 30,
              buttonType: CustomIconButtonType.OUTLINED,
              onPressed: () => currentBloc(context).add(const NoteSelectionServerSynced()),
            ),
            CustomIconButton(
              enabled: state.currentFolder.isRecent == false,
              icon: Icons.create_new_folder_rounded,
              tooltipKey: state.currentFolder.isRecent ? "available.in.different.view" : "note.selection.create.folder",
              size: 30,
              buttonType: CustomIconButtonType.FILLED_TONAL,
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
    return const SizedBox();
  }

  @override
  Future<bool> customBackNavigation(BuildContext context) async {
    final Completer<bool> completer = Completer<bool>();
    currentBloc(context).add(NoteSelectionNavigatedBack(completer: completer));
    return completer.future;
  }

  @override
  String get pageName => "note selection";
}
