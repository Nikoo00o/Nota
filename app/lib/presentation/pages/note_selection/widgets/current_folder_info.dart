import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/custom_card.dart';
import 'package:flutter/material.dart';

class CurrentFolderInfo extends BlocPageChild<NoteSelectionBloc, NoteSelectionState> {
  final StructureFolder folder;

  static const double iconSize = 30;

  const CurrentFolderInfo({
    required this.folder,
  });

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    if (folder.isTopLevel) {
      return const SizedBox();
    }
    return CustomCard(
      color: colorTertiaryContainer(context),
      onTap: () => currentBloc(context).add(const NoteSelectionNavigatedBack(completer: null, ignoreSearch: true)),
      icon: Icons.drive_file_move_rtl,
      title: "..${StructureItem.delimiter}${_getParentName(context)}",
      description: translate(context, "note.selection.current.folder.info", keyParams: <String>[_getParentPath(context)]),
      alignDescriptionRight: false,
      toolTip: "note.selection.navigate.to.parent",
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
        buffer.write(translate(context, StructureItem.rootFolderNames.first)); // special case for move to visualize that
        // its the root folder
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
