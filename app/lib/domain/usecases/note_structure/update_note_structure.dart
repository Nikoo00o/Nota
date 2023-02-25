import 'package:app/core/enums/note_sorting.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This updates the current note and the "recent" directory of the [NoteStructureRepository]
///
/// This is called at the end of each use case that changes the structure like [CreateStructureItem],
/// [MoveStructureItem], [RenameCurrentStructureItem], [DeleteStructureItem] and [FetchNewNoteStructure].
///
/// Afterwards [GetCurrentStructureItem] should be called to return a new copy of the [currentItem]!
///
/// [FetchNewNoteStructure] must be called before, otherwise this throws [ErrorCodes.INVALID_PARAMS] if [root] is null!
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
    final List<StructureNote> notes = noteStructureRepository.root!.getAllNotes();

    noteStructureRepository.recent = StructureFolder(
      name: StructureFolder.recentFolderNames.first,
      directParent: null,
      canBeModified: false,
      children: notes,
      sorting: NoteSorting.BY_DATE,
    );
  }

  void _updateCurrentItem() {
    StructureItem? current = noteStructureRepository.currentItem;

    // find a matching note
    if (current is StructureNote) {
      final StructureNote? newItem =
          noteStructureRepository.getNoteById(noteId: current.id, useRootAsParent: current.topMostParent.isRecent == false);
      if (newItem != null) {
        current = newItem;
      } else {
        current = current.getParent();
      }
    }

    // find a matching parent folder
    if (current is StructureFolder && current.topMostParent.isRoot) {
      while (current!.directParent != null) {
        final StructureFolder? newItem = noteStructureRepository.getFolderByPath(current.path);
        if (newItem != null) {
          current = newItem;
          break;
        } else {
          current = current.directParent; // will never be in recent, so this is allowed
        }
      }
    }

    // otherwise it is "recent"
    if (current is! StructureFolder || current.isRoot == false) {
      current = noteStructureRepository.recent;
    }

    // set item
    noteStructureRepository.currentItem = current;
  }
}
