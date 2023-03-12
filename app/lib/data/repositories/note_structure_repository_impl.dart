import 'dart:async';

import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:shared/core/utils/logger/logger.dart';

class NoteStructureRepositoryImpl extends NoteStructureRepository {
  final LocalDataSource localDataSource;

  NoteStructureRepositoryImpl({
    required this.localDataSource,
  });

  @override
  List<StructureFolder?> get topLevelFolders => <StructureFolder?>[root, recent, moveSelection];

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

  final StreamController<StructureUpdateBatch> _streamController = StreamController<StructureUpdateBatch>();
  Stream<StructureUpdateBatch>? _broadcastStream;

  @override
  Future<StreamSubscription<StructureUpdateBatch>> listenToStructureUpdates(
      FutureOr<void> Function(StructureUpdateBatch newUpdate) callbackFunction) async {
    _broadcastStream ??= _streamController.stream.asBroadcastStream();
    return _broadcastStream!.listen(callbackFunction);
  }

  @override
  Future<void> addNewStructureUpdate(
      StructureItem newCurrentItem, Map<TranslationString, StructureFolder> newTopLevelFolders) async {
    _streamController.sink.add(StructureUpdateBatch(currentItem: newCurrentItem, topLevelFolders: newTopLevelFolders));
  }
}
