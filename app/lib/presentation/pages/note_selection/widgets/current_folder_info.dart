import 'package:app/core/enums/search_status.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/custom_card.dart';
import 'package:flutter/material.dart';

final class CurrentFolderInfo extends BlocPageChild<NoteSelectionBloc, NoteSelectionState> {
  final StructureFolder folder;

  static const double iconSize = 30;

  const CurrentFolderInfo({
    required this.folder,
  });

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    if (folder.isTopLevel) {
      if (folder.isMove) {
        return CustomCard(
          color: colorSurfaceVariant(context),
          onTap: null,
          icon: Icons.info,
          title: translate(context, StructureItem.rootFolderNames.first),
          description: translate(context, "note.selection.move.info"),
          alignDescriptionRight: false,
        );
      } else {
        return createBlocBuilder(builder: _buildInfo);
      }
    }
    return CustomCard(
      color: colorTertiaryContainer(context),
      onTap: () => currentBloc(context).add(const NoteSelectionNavigateToParent()),
      icon: Icons.drive_file_move_rtl,
      title: "..${StructureItem.delimiter}${_getParentName(context)}",
      description:
          translate(context, "note.selection.current.folder.info", keyParams: <String>[_getParentPath(context)]),
      alignDescriptionRight: false,
      toolTip: translate(context, "note.selection.navigate.to.parent"),
    );
  }

  Widget _buildInfo(BuildContext context, NoteSelectionState state) {
    if (state.isInitialized && state.searchStatus != SearchStatus.DISABLED && state.searchInput == null) {
      return _buildSearchInfo(context, state);
    } else if (state.isInitialized && state.currentFolder.amountOfChildren == 0) {
      return _buildEmptyInfo(context, state);
    } else {
      return const SizedBox();
    }
  }

  Widget _buildEmptyInfo(BuildContext context, NoteSelectionState state) {
    return CustomCard(
      color: colorSurfaceVariant(context),
      onTap: null,
      icon: Icons.info,
      title: translate(context, "note.selection.empty.title"),
      description: translate(context, "note.selection.empty.description"),
      alignDescriptionRight: false,
    );
  }

  Widget _buildSearchInfo(BuildContext context, NoteSelectionState state) {
    final String titleKey = state.searchStatus == SearchStatus.EXTENDED
        ? "note.selection.search.mode.extended"
        : "note.selection.search.mode.default";
    final String descriptionKey = state.searchStatus == SearchStatus.EXTENDED
        ? "note.selection.search.mode.extended.description"
        : "note.selection.search.mode.default.description";
    return CustomCard(
      color: colorSurfaceVariant(context),
      onTap: null,
      icon: Icons.info,
      title: translate(context, titleKey),
      description: translate(context, descriptionKey),
      alignDescriptionRight: false,
    );
  }

  String _getParentName(BuildContext context) {
    final StructureFolder parent = folder.getParent()!;
    if (parent.isTopLevel) {
      return translate(context, parent.name);
    } else {
      return parent.name;
    }
  }

  String _getParentPath(BuildContext context) {
    final StructureFolder parent = folder.getParent()!;
    final StringBuffer buffer = StringBuffer();
    buffer.write(StructureItem.delimiter);
    if (parent.isTopLevel) {
      if (parent.isMove) {
        // special case for move to visualize that its the root folder
        buffer.write(translate(context, StructureItem.rootFolderNames.first));
      } else {
        buffer.write(translate(context, parent.path));
      }
    } else {
      buffer.write(parent.path);
    }
    buffer.write(StructureItem.delimiter);
    return buffer.toString();
  }
}
