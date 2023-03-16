import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';

class NoteEditState extends PageState {
  const NoteEditState([super.properties = const <String, Object?>{}]);
}

class NoteEditStateInitialised extends NoteEditState {
  final StructureNote currentNote;
  final bool isEditing;
  final String currentSearchPosition;
  final String searchPositionSize;

  NoteEditStateInitialised({
    required this.currentNote,
    required this.isEditing,
    required this.currentSearchPosition,
    required this.searchPositionSize,
  }) : super(<String, Object?>{
          "currentNote": currentNote,
          "isEditing": isEditing,
          "currentSearchPosition": currentSearchPosition,
          "searchPositionSize": searchPositionSize,
        });
}
