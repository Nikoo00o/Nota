import 'package:app/core/enums/note_sorting.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_structure/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_structure/get_structure_folders.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This refreshes the cached note structure by loading a new structure from the locally saved account data. This
/// overrides the [NoteStructureRepository.root] variable.
///
/// This is called by the use cases [TransferNotes], [GetOriginalStructureItem], [GetCurrentStructureItem] and
/// [GetCurrentStructureFolders].
///
/// This calls the use case [UpdateNoteStructure].
///
/// This can throw the exceptions of [GetLoggedInAccount], but perform no additional input validation!
class FetchNewNoteStructure extends UseCase<void, NoParams> {
  final NoteStructureRepository noteStructureRepository;
  final UpdateNoteStructure updateNoteStructure;
  final GetLoggedInAccount getLoggedInAccount;

  const FetchNewNoteStructure({
    required this.noteStructureRepository,
    required this.updateNoteStructure,
    required this.getLoggedInAccount,
  });

  @override
  Future<void> execute(NoParams params) async {
    final ClientAccount account = await getLoggedInAccount.call(const NoParams());

    noteStructureRepository.root = StructureFolder(
      name: StructureFolder.rootFolderNames.first,
      directParent: null,
      canBeModified: false,
      children: List<StructureItem>.empty(growable: true),
      sorting: NoteSorting.BY_NAME,
      changeParentOfChildren: true,
    );

    for (final NoteInfo note in account.noteInfoList) {
      if (note.isDeleted == false) {
        // add all notes
        final String name = await SecurityUtilsExtension.decryptStringAsync2(note.encFileName, account.decryptedDataKey!);
        _addNote(note, noteStructureRepository.root!, name);
      }
    }

    noteStructureRepository.root!.sortChildren(recursive: true); // only sort once afterwards for performance

    Logger.info("Fetched the new note structure for root:\n${noteStructureRepository.root}");

    await updateNoteStructure.call(const UpdateNoteStructureParams(originalItem: null)); // update note structure
  }

  void _addNote(NoteInfo note, StructureFolder targetFolder, String decryptedName) {
    final List<String> path = decryptedName.split(StructureItem.delimiter);

    if (path.length == 1) {
      // directly add note. the directParent will be set by addChild
      targetFolder.addChild(StructureNote(
        name: decryptedName,
        directParent: null,
        canBeModified: true,
        id: note.id,
        lastModified: note.lastEdited,
      ));
      Logger.verbose("added note $decryptedName in ${targetFolder.path}");
    } else {
      // parse folders from path and create folders first, then the note
      final String subFolderName = path.removeAt(0);
      final String remainingPath = path.join(StructureItem.delimiter);
      StructureFolder? subFolder = targetFolder.getDirectFolderByName(subFolderName, deepCopy: false);

      if (subFolder == null) {
        // create folder if it does not exist. the directParent will be set by addChild
        targetFolder.addChild(StructureFolder(
          name: subFolderName,
          directParent: null,
          canBeModified: true,
          children: List<StructureItem>.empty(growable: true),
          sorting: targetFolder.sorting,
          changeParentOfChildren: true,
        ));

        // important: update the reference (will not be null afterwards!)
        subFolder = targetFolder.getDirectFolderByName(subFolderName, deepCopy: false);
        Logger.verbose("created new folder ${subFolder!.path}");
      }

      _addNote(note, subFolder, remainingPath); // recursive call to add the note to the sub folder
    }
  }
}
