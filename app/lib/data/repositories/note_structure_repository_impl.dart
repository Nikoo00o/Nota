import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:shared/core/utils/logger/logger.dart';

class NoteStructureRepositoryImpl extends NoteStructureRepository {
  final LocalDataSource localDataSource;

  NoteStructureRepositoryImpl({
    required this.localDataSource,
  });

  @override
  StructureNote? getNoteById({required int noteId, required bool useRootAsParent}) {
    if (useRootAsParent) {
      return root?.getNoteById(noteId);
    } else {
      return recent?.getNoteById(noteId);
    }
  }

  @override
  StructureFolder? getFolderByPath(String path, {required bool deepCopy}) => root?.getFolderByPath(path, deepCopy: deepCopy);

  @override
  Future<int> getNewClientNoteCounter() async {
    int? counter = await localDataSource.getClientNoteCounter();
    counter ??= 0;
    counter -= 1;
    await localDataSource.setClientNoteCounter(counter);
    Logger.debug("Returned new client note counter $counter");
    return counter;
  }
}
