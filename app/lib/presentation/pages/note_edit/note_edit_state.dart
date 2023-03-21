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
  /// This is only needed to rebuild the state
  final int searchLength;

  NoteEditStateInitialised({
    required this.currentNote,
    required this.isEditing,
    required this.currentSearchPosition,
    required this.searchPositionSize,
    required this.searchLength,
  }) : super(<String, Object?>{
          "currentNote": currentNote,
          "isEditing": isEditing,
          "currentSearchPosition": currentSearchPosition,
          "searchPositionSize": searchPositionSize,
          "searchLength": searchLength,
        });
}
