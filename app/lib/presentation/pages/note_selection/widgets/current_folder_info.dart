import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
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
    return Card(
      color: colorTertiaryContainer(context),
      child: ListTile(
        isThreeLine: true,
        dense: true,
        minLeadingWidth: iconSize,
        leading: const SizedBox(
          height: double.infinity,
          child: Icon(Icons.drive_file_move_rtl),
        ),
        title: Text(
          "..${StructureItem.delimiter}${_getParentName(context)}",
          style: textTitleMedium(context),
          maxLines: 1,
          softWrap: false,
        ),
        subtitle: Text(
          translate(context, "note.selection.current.folder.info", keyParams: <String>[_getParentPath(context)]),
          softWrap: true,
          style: theme(context).textTheme.bodySmall?.copyWith(color: colorOnSurfaceVariant(context)),
        ),
        onTap: () => currentBloc(context).add(const NoteSelectionNavigatedBack(completer: null)),
      ),
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
      buffer.write(translate(context, parent.path));
    } else {
      buffer.write(parent.path);
    }
    buffer.write(StructureItem.delimiter);
    return buffer.toString();
  }
}
