import 'package:app/core/enums/note_sorting.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/fetch_new_note_structure.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This updates the current note and the "recent" directory of the [NoteStructureRepository]
///
/// This is called at the end of each use case that changes the structure like [CreateStructureItem],
/// [MoveStructureItem], [RenameCurrentStructureItem], [DeleteStructureItem] and [FetchNewNoteStructure].
///
/// Afterwards [GetCurrentStructureItem] should be called to return a new copy of the [currentItem]!
///
/// [FetchNewNoteStructure] must be called before, otherwise this throws [ErrorCodes.INVALID_PARAMS] if
/// [NoteStructureRepository.root] is null!
class UpdateNoteStructure extends UseCase<void, NoParams> {
  final NoteStructureRepository noteStructureRepository;

  const UpdateNoteStructure({required this.noteStructureRepository});

  @override
  Future<void> execute(NoParams params) async {
    if (noteStructureRepository.root == null) {
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    _updateRecentNotes();

    _updateCurrentItem();
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

  void _updateCurrentItem() {
    StructureItem? current = noteStructureRepository.currentItem;

    // find a matching note
    if (current is StructureNote) {
      final StructureNote? newItem =
          noteStructureRepository.getNoteById(noteId: current.id, useRootAsParent: current.topMostParent.isRecent == false);
      if (newItem != null) {
        current = newItem; // not deleted note
      } else {
        current = current.getParent(); // returns either direct parent of the "root" tree, or "recent" itself
      }
    }

    if (current is StructureFolder) {
      if (current.isRecent) {
        current = noteStructureRepository.recent;
      } else {
        // find a matching parent folder for the "root" tree
        while (current!.directParent != null) {
          final StructureFolder? newItem = noteStructureRepository.getFolderByPath(current.path);
          if (newItem != null) {
            current = newItem; // find a not deleted folder higher up
            break;
          } else {
            current = current.directParent; // will never be in recent, so this is allowed
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
