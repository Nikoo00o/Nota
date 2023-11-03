import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/widgets/base_note/base_note_bloc.dart';
import 'package:app/presentation/widgets/base_note/base_note_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:flutter/material.dart';

final class NoteBottomBar<Bloc extends BaseNoteBloc<State>, State extends BaseNoteState>
    extends BlocPageChild<Bloc, State> {
  const NoteBottomBar();

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return createBlocSelector<StructureItem?>(
      selector: (State state) => state.currentItem,
      builder: (BuildContext context, StructureItem? currentItem) {
        if (currentItem == null) {
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
                  keyParams: <String>["${StructureItem.delimiter}${currentItem.path}"],
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
                  keyParams: <String>[currentItem.lastModifiedFormatted],
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
