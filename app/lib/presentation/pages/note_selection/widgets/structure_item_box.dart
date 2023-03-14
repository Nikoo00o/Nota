import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

class StructureItemBox extends BlocPageChild<NoteSelectionBloc, NoteSelectionState> {
  final StructureItem item;
  final int index;
  static const double iconSize = 30;

  const StructureItemBox({
    required this.item,
    required this.index,
  });

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return Card(
      color: item is StructureFolder ? colorSecondaryContainer(context) : colorPrimaryContainer(context),
      child: ListTile(
        isThreeLine: true,
        dense: true,
        minLeadingWidth: iconSize,
        leading: SizedBox(
          height: double.infinity,
          child: Icon(item is StructureFolder ? Icons.folder : Icons.edit_note, size: iconSize),
        ),
        title: Text(
          item.name,
          style: textTitleMedium(context),
          maxLines: 1,
          softWrap: false,
        ),
        subtitle: Text(
          _getDescription(context),
          maxLines: 2,
          textAlign: TextAlign.right,
          style: theme(context).textTheme.bodySmall?.copyWith(color: colorOnSurfaceVariant(context)),
        ),
        onTap: () => currentBloc(context).add(NoteSelectionItemClicked(index: index)),
      ),
    );
  }

  String _getDescription(BuildContext context) {
    if (item is StructureFolder) {
      if (item.lastModified.isBefore(DateTime.fromMillisecondsSinceEpoch(1))) {
        return translate(context, "note.selection.folder.needs.note");
      }
      return translate(context, "note.selection.folder.description", keyParams: <String>[item.lastModifiedFormatted]);
    } else {
      return translate(context, "note.selection.note.description", keyParams: <String>[item.lastModifiedFormatted]);
    }
  }
}
