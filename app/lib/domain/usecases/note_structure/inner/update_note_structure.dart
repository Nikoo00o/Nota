import 'package:app/core/enums/note_sorting.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/delete_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_structure/move_current_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This newly creates the [NoteStructureRepository.recent] as a deep copy of [NoteStructureRepository.root]!
///
/// This also updates the [NoteStructureRepository.currentItem] reference to a matching item from either recent, or root
/// by using either the old current item, or the [UpdateNoteStructureParams.originalItem] for comparison!
///
/// The [UpdateNoteStructureParams.originalItem] should be retrieved from [GetOriginalStructureItem].
///
/// If "recent" is the parent and the item is a folder, then it will always navigate to the recent folder. Otherwise for
/// root the folder path gets compared. For notes the id will be compared in both cases.
/// Per default if both current item and original item are null, then the resulting item will be "recent".
///
/// This is called at the end of each use case that changes the structure like [CreateStructureItem],
/// [MoveCurrentStructureItem], [ChangeCurrentStructureItem], [DeleteCurrentStructureItem] and [FetchNewNoteStructure].
///
/// Afterwards [GetCurrentStructureItem] should be called again by the ui to return a new copy of the
/// [NoteStructureRepository.currentItem]!
///
/// [FetchNewNoteStructure] must be have been called at least once before, otherwise this throws
/// [ErrorCodes.INVALID_PARAMS] if  [NoteStructureRepository.root] is null!
class UpdateNoteStructure extends UseCase<void, UpdateNoteStructureParams> {
  final NoteStructureRepository noteStructureRepository;

  const UpdateNoteStructure({required this.noteStructureRepository});

  @override
  Future<void> execute(UpdateNoteStructureParams params) async {
    if (noteStructureRepository.root == null) {
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    _updateRecentNotes();

    _updateCurrentItem(params.originalItem);
  }

  void _updateRecentNotes() {
    // first make a deep copy of root and change the top most folder to recent
    noteStructureRepository.recent = noteStructureRepository.root!.copyWith(
      newName: StructureFolder.recentFolderNames.first,
      newSorting: NoteSorting.BY_DATE,
      changeParentOfChildren: true,
    );

    // then get all notes and add them as children directly
    final List<StructureNote> notes = noteStructureRepository.recent!.getAllNotes();
    noteStructureRepository.recent!.replaceChildren(notes);

    Logger.debug("Updated the recent notes to:\n${noteStructureRepository.recent}");
  }

  void _updateCurrentItem(StructureItem? originalItem) {
    StructureItem? current = originalItem?? noteStructureRepository.currentItem; // either use the original item
    // replacement, or the old current item to search a match.

    // find a matching note
    if (current is StructureNote) {
      final StructureNote? newItem =
          noteStructureRepository.getNoteById(noteId: current.id, useRootAsParent: current.topMostParent.isRecent == false);
      if (newItem != null) {
        current = newItem; // not deleted note
      } else {
        current = current.getParent(); // returns either direct parent of the "root" tree, or "recent" itself
        Logger.verbose("The current note had to be changed to the parent:\n$current");
      }
    }

    if (current is StructureFolder) {
      if (current.isRecent) {
        current = noteStructureRepository.recent;
      } else {
        // find a matching parent folder for the "root" tree
        while (current!.directParent != null) {
          final StructureFolder? newItem = noteStructureRepository.getFolderByPath(current.path, deepCopy: false);
          if (newItem != null) {
            current = newItem; // find a not deleted folder higher up
            break;
          } else {
            current = current.directParent; // will never be in recent, so this is allowed
            Logger.verbose("The current folder had to be changed to the parent:\n$current");
          }
        }
      }
    }

    // per default if current is null, it should always be the recent folder
    current ??= noteStructureRepository.recent;

    // set item
    noteStructureRepository.currentItem = current;
    Logger.debug("Updated the current item to:\n$current");
  }
}

/// The [originalItem] is optional to move the [NoteStructureRepository.currentItem] to a matching item in its own parent
/// folder structure! Otherwise the old current item will bef used for comparison!
class UpdateNoteStructureParams{
  final StructureItem? originalItem;

  const UpdateNoteStructureParams({
    required this.originalItem,
  });
}