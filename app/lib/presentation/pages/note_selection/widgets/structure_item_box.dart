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

  const StructureItemBox({
    required this.item,
    required this.index,
  });

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {

    // todo: probably move the onpressed to the card itself. change icon. add last edited. maybe change size and make them
    //  round. or use something different than list tile.

    return Card(
      elevation: 5,
      color: item is StructureFolder ?  colorSecondaryContainer(context) : colorPrimaryContainer(context),
      child: ListTile(
        isThreeLine: true,
        dense: true,
        title: Text(item.name),
        subtitle: Text(
          'Here is a second line',
          style: theme(context).textTheme.bodySmall?.copyWith(color: colorOnSurfaceVariant(context)),
        ),
        onTap: () => currentBloc(context).add(NoteSelectionItemClicked(index: index)),
        leading: Icon(item is StructureFolder ? Icons.folder : Icons.edit_note),
      ),
    );
  }
}
