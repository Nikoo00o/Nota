import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/usecases/note_structure/update_note_structure.dart';

class NoteStructureRepositoryImpl extends NoteStructureRepository {
  @override
  StructureNote? getNoteById({required int noteId, required bool useRootAsParent}) {
    if (useRootAsParent) {
      return root?.getNoteById(noteId);
    } else {
      return recent?.getNoteById(noteId);
    }
  }

  @override
  StructureFolder? getFolderByPath(String path) => root?.getFolderByPath(path);
}
