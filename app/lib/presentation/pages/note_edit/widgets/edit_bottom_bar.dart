import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/pages/note_edit/note_edit_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

class EditBottomBar extends BlocPageChild<NoteEditBloc, NoteEditState> {
  const EditBottomBar();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return partWithState;
  }

  @override
  Widget buildWithState(BuildContext context, NoteEditState state) {
    if (state is NoteEditStateInitialised) {
      return BottomAppBar(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              translate(
                context,
                "note.edit.path",
                keyParams: <String>["${StructureItem.delimiter}${state.currentNote.path}"],
              ),
              textAlign: TextAlign.left,
              maxLines: 2,
              style: textLabelMedium(context).copyWith(color: colorTertiary(context)),
            ),
            const SizedBox(height: 5),
            Text(
              translate(
                context,
                "note.selection.note.description",
                keyParams: <String>[state.currentNote.lastModifiedFormatted],
              ),
              textAlign: TextAlign.left,
              maxLines: 1,
              style: textLabelMedium(context).copyWith(color: colorOnSurfaceVariant(context)),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }
}
