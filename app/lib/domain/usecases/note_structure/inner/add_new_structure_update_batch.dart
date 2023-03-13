import 'dart:async';

import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_folders.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This adds a new streamed update by calling [NoteStructureRepository.addNewStructureUpdate] which will be received
/// by [GetStructureUpdatesStream]!
///
/// For this the use cases [GetCurrentStructureItem] and [GetStructureFolders] will be called internally (because as
/// params they would have recursive dependencies!)!
class AddNewStructureUpdateBatch extends UseCase<void, NoParams> {
  final NoteStructureRepository noteStructureRepository;

  const AddNewStructureUpdateBatch({required this.noteStructureRepository});

  @override
  Future<void> execute(NoParams params) async {
    // add the end add a new event to the stream to update the ui. this needs to be direct with [sl], because otherwise
    // the use cases would import each other in a chain! Because those 2 use cases are very small and will call nothing
    // else at this point, this is ok!
    final StructureItem currentItem = await sl<GetCurrentStructureItem>().call(const NoParams());
    final Map<TranslationString, StructureFolder> topLevelFolders =
        await sl<GetStructureFolders>().call(const GetStructureFoldersParams(includeMoveFolder: true));
    await noteStructureRepository.addNewStructureUpdate(
      currentItem,
      topLevelFolders,
    );

    Logger.verbose("added new structure update with current ${currentItem.path} and ${topLevelFolders.length} top level "
        "folders");
  }
}
