import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

class CurrentFolderInfo extends BlocPageChild<NoteSelectionBloc, NoteSelectionState> {
  final StructureFolder folder;

  const CurrentFolderInfo({
    required this.folder,
  });

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    if (folder.isTopLevel) {
      return const SizedBox();
    }

    // maybe add description of current path where we are. or show full path in title with diescription navigate back

    return Card(
      elevation: 5,
      color: colorTertiaryContainer(context),
      child: ListTile(
        isThreeLine: true,
        dense: true,
        title: Text("..${StructureItem.delimiter}${_getParentName(context)}"),
        subtitle: Text(
          'Here is a second line',
          style: theme(context).textTheme.bodySmall?.copyWith(color: colorOnSurfaceVariant(context)),
        ),
        onTap: () => currentBloc(context).add(const NoteSelectionNavigatedBack(completer: null)),
        leading: const Icon(Icons.drive_file_move_rtl),
      ),
    );
  }

  String _getParentName(BuildContext context) {
    final StructureFolder parent = folder.getParent()!;
    if (parent.isTopLevel) {
      return translate(context, parent.path);
    } else {
      return parent.path;
    }
  }
}

// build empty if this is top level, otherwise path of parent with "../"
