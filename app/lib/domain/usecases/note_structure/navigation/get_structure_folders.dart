import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This returns a a list of deep copies of the top level note structure folders (first "root" and second element "recent").
///
/// The parent folder of children of recent will not be changed!
///
/// This will return the [NoteStructureRepository.topLevelFolders], but with the users custom favourites added before the
/// move folder
///
/// The last folder will always be the move folder and it should be ignored!!!
///
/// This should be used to build the menu items for navigating to the folders.
///
/// This can not be used to modify the note structure!
///
/// This can call the use case [FetchNewNoteStructure] if there is no note structure cached.
///
/// This can throw the exceptions of [GetLoggedInAccount], but perform no additional input validation!
///
/// As an alternative, you can use [GetStructureUpdatesStream] to receive streamed updates instead!
class GetStructureFolders extends UseCase<Map<TranslationString, StructureFolder>, GetStructureFoldersParams> {
  final NoteStructureRepository noteStructureRepository;
  final FetchNewNoteStructure fetchNewNoteStructure;

  const GetStructureFolders({
    required this.noteStructureRepository,
    required this.fetchNewNoteStructure,
  });

  @override
  Future<Map<TranslationString, StructureFolder>> execute(GetStructureFoldersParams params) async {
    if (noteStructureRepository.root == null) {
      await fetchNewNoteStructure.call(const NoParams());
    }

    Logger.verbose("Returned a new deep copied list of the top level folders");

    final Iterable<MapEntry<TranslationString, StructureFolder>> entries =
        noteStructureRepository.topLevelFolders.map<MapEntry<TranslationString, StructureFolder>>((StructureFolder? folder) {
      final bool changeParentOfChildren = folder!.isRecent == false; // don't change the parent of children of recent,
      // because recent has the notes as direct children which have their folder structure as direct parents!
      final StructureFolder newFolder = folder.copyWith(changeParentOfChildren: changeParentOfChildren);
      String translationKey = "empty.param.1";
      if (newFolder.isRecent) {
        translationKey = StructureItem.recentFolderNames.first;
      } else if (newFolder.isRoot) {
        translationKey = StructureItem.rootFolderNames.first;
      } else if (newFolder.isMove) {
        translationKey = StructureItem.moveFolderNames.first;
      }

      return MapEntry<TranslationString, StructureFolder>(TranslationString(translationKey), newFolder);
    });

    final Map<TranslationString, StructureFolder> result = Map<TranslationString, StructureFolder>.fromEntries(entries);

    if (params.includeMoveFolder == false) {
      result.remove(TranslationString(StructureItem.moveFolderNames.first));
    }
    //todo: insert user custom favourite folders before the move folder, but after the other folders
    return result;
  }
}

class GetStructureFoldersParams {
  /// if false, then the move folder will not be included in the output
  final bool includeMoveFolder;

  const GetStructureFoldersParams({
    required this.includeMoveFolder,
  });
}
