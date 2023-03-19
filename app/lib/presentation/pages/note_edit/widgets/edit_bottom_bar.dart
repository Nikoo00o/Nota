import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/presentation/pages/note_edit/note_edit_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

class EditBottomBar extends BlocPageChild<NoteEditBloc, NoteEditState> {
  const EditBottomBar();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return createBlocSelector<StructureNote?>(
      selector: (NoteEditState state) => state is NoteEditStateInitialised ? state.currentNote : null,
      builder: (BuildContext context, StructureNote? currentNote) {
        if (currentNote == null) {
          return const SizedBox();
        }
        return BottomAppBar(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                translate(
                  context,
                  "note.edit.path",
                  keyParams: <String>["${StructureItem.delimiter}${currentNote.path}"],
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
                  keyParams: <String>[currentNote.lastModifiedFormatted],
                ),
                textAlign: TextAlign.left,
                maxLines: 1,
                style: textLabelMedium(context).copyWith(color: colorOnSurfaceVariant(context)),
              ),
            ],
          ),
        );
      },
    );
  }
}
