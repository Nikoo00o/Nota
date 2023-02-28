import 'package:app/core/enums/note_sorting.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/delete_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/finish_move_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This newly creates the [NoteStructureRepository.recent] as a deep copy of [NoteStructureRepository.root]!
///
/// This also updates the [NoteStructureRepository.currentItem] reference to a matching item from either recent, or root
/// by using either the old current item, or the [UpdateNoteStructureParams.originalItem] for comparison!
/// The top most parent (root vs recent) will always get matched only from the current item if it is not null and not from
/// the original. This can be changed with the param [UpdateNoteStructureParams.resetCurrentItem].
///
/// The [UpdateNoteStructureParams.originalItem] should be retrieved from [GetOriginalStructureItem] and it will always
/// have [NoteStructureRepository.root] as its top most parent.
///
/// If "recent" is the top most parent of the current item and the item is a folder, then it will always navigate to the
/// recent folder. Otherwise for root as top most parent the folder path gets compared. For notes the id will be compared
/// in both cases.
/// Per default if both current item and original item are null, then the resulting item will be "recent".
/// If the current item is not available anymore, it will navigate to the parent folder!
///
/// This is called at the end of each use case that changes the structure like [CreateStructureItem],
/// [FinishMoveStructureItem], [ChangeCurrentStructureItem], [DeleteCurrentStructureItem] and [FetchNewNoteStructure].
///
/// Afterwards [GetCurrentStructureItem] should be called again by the ui to return a new copy of the
/// [NoteStructureRepository.currentItem]!
///
/// [FetchNewNoteStructure] must be have been called at least once before, otherwise this throws
/// [ErrorCodes.INVALID_PARAMS] if [NoteStructureRepository.root] is null!
class UpdateNoteStructure extends UseCase<void, UpdateNoteStructureParams> {
  final NoteStructureRepository noteStructureRepository;

  const UpdateNoteStructure({required this.noteStructureRepository});

  @override
  Future<void> execute(UpdateNoteStructureParams params) async {
    if (noteStructureRepository.root == null) {
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    _updateRecentNotes();

    _updateMoveSelection();

    if (params.resetCurrentItem) {
      noteStructureRepository.currentItem = null; // depending on the params reset the current item, so that the top most
      // parent of the originalItem will be used for comparison!
    }

    _updateCurrentItem(params.originalItem);

    // todo: maybe send an event to the bloc here (and also in the navigate use cases) instead of updating it manually
    //  after calling this use case with a call to [GetCurrentStructureItem]
  }

  void _updateRecentNotes() {
    // first make a deep copy of root and change the top most folder to recent
    noteStructureRepository.recent = noteStructureRepository.root!.copyWith(
      newName: StructureItem.recentFolderNames.first,
      newSorting: NoteSorting.BY_DATE,
      changeParentOfChildren: true,
    );

    // then get all notes and add them as children directly
    final List<StructureNote> notes = noteStructureRepository.recent!.getAllNotes();
    noteStructureRepository.recent!.replaceChildren(notes);

    Logger.debug("Updated the recent notes to:\n${noteStructureRepository.recent}");
  }

  void _updateMoveSelection() {
    // first make a deep copy of root, change top most folder and the modifiable bool
    noteStructureRepository.moveSelection = noteStructureRepository.root!.copyWith(
      newName: StructureItem.moveFolderNames.first,
      newSorting: NoteSorting.BY_NAME,
      changeParentOfChildren: true,
      newCanBeModified: false,
      changeCanBeModifiedOfChildrenRecursively: true,
    );

    // then remove all notes from the move selection
    noteStructureRepository.moveSelection!.removeAllNotes();

    Logger.debug("Updated the move selection to:\n${noteStructureRepository.moveSelection}");
  }

  void _updateCurrentItem(StructureItem? originalItem) {
    final StructureItem? currentItem = noteStructureRepository.currentItem;
    StructureItem? compareItem = originalItem ?? currentItem; // prefer the original item for
    // comparison if it is set and otherwise use the current item.

    if (compareItem == null) {
      noteStructureRepository.currentItem = noteStructureRepository.recent!;
      Logger.debug("Updated the current item to the default recent"); // special case if there was no current item set before
    } else {
      final StructureFolder topLevelFolder = _getTopLevelFolder(currentItem: currentItem, originalItem: originalItem);
      StructureItem? newCurrentItem;

      // try to find compare item, or any parent of it
      while (newCurrentItem == null && compareItem != null) {
        newCurrentItem = _findMatchingItem(folderToSearch: topLevelFolder, compareItem: compareItem);
        if (newCurrentItem == null) {
          Logger.debug("Could not find ${compareItem.path} so far. Continuing with parent."); // also compare parents,
          // because the item might have been deleted (and then it should jump to the parent)
          compareItem = compareItem.getParent();
        }
      }

      if (newCurrentItem == null) {
        noteStructureRepository.currentItem = topLevelFolder; // the compare item and its parents was not found in the top
        // level folder
        Logger.debug("Updated the current item to the top level folder:\n$topLevelFolder");
      } else {
        noteStructureRepository.currentItem = newCurrentItem;
        Logger.debug("Found a match to update the current item:\n$newCurrentItem");
      }
    }
  }

  /// Returns a reference to matching top level folder ("root, or "recent") by first checking the [currentItem] if its not
  /// null, then checking the [originalItem] if its not null and otherwise returning [NoteStructureRepository.recent].
  StructureFolder _getTopLevelFolder({required StructureItem? currentItem, required StructureItem? originalItem}) {
    //first check current item, then original item
    if (currentItem != null) {
      if (currentItem.topMostParent.isRecent) {
        return noteStructureRepository.recent!;
      } else if (currentItem.topMostParent.isRoot) {
        return noteStructureRepository.root!;
      } else if (currentItem.topMostParent.isMove) {
        return noteStructureRepository.moveSelection!;
      }
      Logger.warn("The current item was not null, but did not have a top level folder:\n$currentItem");
    } else if (originalItem != null) {
      if (originalItem.topMostParent.isRecent) {
        return noteStructureRepository.recent!;
      } else if (originalItem.topMostParent.isRoot) {
        return noteStructureRepository.root!;
      } else if (originalItem.topMostParent.isMove) {
        return noteStructureRepository.moveSelection!;
      }
      Logger.warn("The original item was not null, but did not have a top level folder:\n$currentItem");
    }
    return noteStructureRepository.recent!; //otherwise the default is always recent
  }

  /// Finds the item in [folderToSearch] that matches the [compareItem].
  ///
  /// The matching compares paths for folders and note ids for notes!
  StructureItem? _findMatchingItem({required StructureFolder folderToSearch, required StructureItem compareItem}) {
    if (compareItem is StructureNote) {
      return folderToSearch.getNoteById(compareItem.id);
    } else if (compareItem is StructureFolder) {
      return folderToSearch.getFolderByPath(compareItem.path, deepCopy: false);
    }
    throw UnimplementedError();
  }
}

/// The [originalItem] is optional to move the [NoteStructureRepository.currentItem] to a matching item in its own parent
/// folder structure! Otherwise the old current item will bef used for comparison!
///
/// The top most parent of the [originalItem] will be ignored if the [NoteStructureRepository.currentItem] is not null.
///
/// If [resetCurrentItem] is true, then the [NoteStructureRepository.currentItem] will be set to null before and then the
/// top most parent will depend on the [originalItem] instead! But if this is the case, then the [originalItem] should not
/// be null!
class UpdateNoteStructureParams {
  final StructureItem? originalItem;

  final bool resetCurrentItem;

  UpdateNoteStructureParams({
    required this.originalItem,
    this.resetCurrentItem = false,
  }) {
    if (resetCurrentItem && originalItem == null) {
      Logger.warn("Called UpdateNoteStructure with resetCurrentItem, but no original item");
    }
    assert(resetCurrentItem == false || originalItem != null,
        "Called UpdateNoteStructure with resetCurrentItem, but no original item");
  }
}
