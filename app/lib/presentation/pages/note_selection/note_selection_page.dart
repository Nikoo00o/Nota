import 'dart:io';
import 'package:app/core/enums/search_status.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/pages/note_selection/widgets/current_folder_info.dart';
import 'package:app/presentation/pages/note_selection/widgets/selection_bottom_bar.dart';
import 'package:app/presentation/pages/note_selection/widgets/selection_search_bar.dart';
import 'package:app/presentation/pages/note_selection/widgets/structure_item_box.dart';
import 'package:app/presentation/widgets/base_note/base_note_page.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

final class NoteSelectionPage extends BaseNotePage<NoteSelectionBloc, NoteSelectionState> {
  const NoteSelectionPage() : super(pagePadding: const EdgeInsets.fromLTRB(5, 0, 5, 0));

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    final Widget body = Scrollbar(controller: currentBloc(context).scrollController, child: bodyWithState);
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return DropTarget(
        onDragDone: (DropDoneDetails detail) {
          currentBloc(context).add(NoteSelectionDroppedFile(details: detail));
        },
        onDragEntered: (DropEventDetails detail) {},
        onDragExited: (DropEventDetails detail) {},
        child: body,
      );
    }
    return body;
  }

  @override
  Widget buildBodyWithState(BuildContext context, NoteSelectionState state) {
    if (state.isInitialized) {
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
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return PreferredSize(
      // default size
      preferredSize: const Size.fromHeight(BlocPage.defaultAppBarHeight),
      child: createBlocSelector<StructureItem?>(
        selector: (NoteSelectionState state) => state.currentItem,
        builder: (BuildContext context, StructureItem? currentItem) {
          if (currentItem == null) {
            return AppBar(); // use empty app bar at first, so that the element gets cached for performance
          } else {
            return createBlocSelector<bool>(
              selector: (NoteSelectionState state) => state.searchStatus != SearchStatus.DISABLED,
              builder: (BuildContext context, bool isSearchEnabled) {
                if (isSearchEnabled) {
                  return AppBar(
                    leading: buildBackButton(context),
                    title: const SelectionSearchBar(),
                    centerTitle: false,
                  );
                } else {
                  return buildTitleAppBar(context, currentItem, withBackButton: false);
                }
              },
            );
          }
        },
      ),
    );
  }

  @override
  Widget? buildMenuDrawer(BuildContext context) => createMenuDrawerWithState(context);

  @override
  Widget buildMenuDrawerWithState(BuildContext context, NoteSelectionState state) {
    // this will only ever show either root, or recent as the selected menu entry
    if (state.isInitialized) {
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
      state.isInitialized && state.currentFolder.topMostParent.topMostParent.isMove == false;

  @override
  Widget buildBottomBar(BuildContext context) => const SelectionBottomBar();

  @override
  String get pageName => "note selection";
}
