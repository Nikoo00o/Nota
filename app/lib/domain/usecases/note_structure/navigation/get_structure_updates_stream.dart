import 'dart:async';

import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/inner/add_new_structure_update_batch.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_folders.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This is an alternative to [GetCurrentStructureItem] and [GetStructureFolders] which returns the changes to the ui as
/// streamed events.
///
/// So every time [UpdateNoteStructure], or [NavigateToItem] are called, the returned listener of this use case will receive a
/// new [StructureUpdateBatch] from the use case [AddNewStructureUpdateBatch] containing a new copy of the current item
/// and top level folders.
///
/// Important: the listener should be closed when the ui widget is disposed!
///
/// Because the stream is async, some events might get lost!
class GetStructureUpdatesStream extends UseCase<StreamSubscription<StructureUpdateBatch>, GetStructureUpdatesStreamParams> {
  final NoteStructureRepository noteStructureRepository;

  const GetStructureUpdatesStream({required this.noteStructureRepository});

  @override
  Future<StreamSubscription<StructureUpdateBatch>> execute(GetStructureUpdatesStreamParams params) async {
    Logger.verbose("added new structure update stream listener");
    return noteStructureRepository.listenToStructureUpdates(params.callbackFunction);
  }
}

class GetStructureUpdatesStreamParams {
  final FutureOr<void> Function(StructureUpdateBatch newUpdate) callbackFunction;

  const GetStructureUpdatesStreamParams({
    required this.callbackFunction,
  });
}
