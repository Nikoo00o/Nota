import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_transfer/fetch_new_note_structure.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This returns a a list of deep copies of the top level note structure folders (first "root" and second element "recent").
/// But the parent folder references for the children are not changed!
///
/// This should be used to build the menu items for navigating to the folders.
///
/// This can not be used to modify the note structure!
///
/// This can call the use case [FetchNewNoteStructure] if there is no note structure cached.
///
/// This can throw the exceptions of [GetLoggedInAccount], but perform no additional input validation!
class GetCurrentStructureFolders extends UseCase<List<StructureFolder>, NoParams> {
  final NoteStructureRepository noteStructureRepository;
  final FetchNewNoteStructure fetchNewNoteStructure;

  const GetCurrentStructureFolders({
    required this.noteStructureRepository,
    required this.fetchNewNoteStructure,
  });

  @override
  Future<List<StructureFolder>> execute(NoParams params) async {
    if (noteStructureRepository.root == null) {
      await fetchNewNoteStructure.call(const NoParams());
    }

    Logger.verbose("Returned a new deep copied list of the top level folders");

    return noteStructureRepository.topLevelFolders
        .map((StructureFolder? folder) => folder!.copyWith(changeParentOfChildren: false))
        .toList();
  }
}
