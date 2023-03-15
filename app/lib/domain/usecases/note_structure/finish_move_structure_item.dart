import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/start_move_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';
import 'package:tuple/tuple.dart';

/// This finishes the move of the [NoteStructureRepository.moveItemSrc] to the new parent target folder
/// [NoteStructureRepository.currentItem]. Afterwards it will navigate back to the item for that the move was started with.
///
/// This should be called after the [StartMoveStructureItem] use case was executed and a folder was selected in the move
/// selection view and either the confirm, or cancel button was pressed (the status is saved inside of the
/// [FinishMoveStructureItemParams.wasConfirmed].
///
/// If the [NoteStructureRepository.currentItem] is not a folder inside of [NoteStructureRepository.moveSelection], then
/// this will throw [ErrorCodes.INVALID_PARAMS]. The same is thrown if the [NoteStructureRepository.moveItemSrc] is null.
///
/// If the source item is a folder this also throws [ErrorCodes.NAME_ALREADY_USED] if there already is another folder with
/// the same name in the target folder!
///
/// This calls the use cases [GetOriginalStructureItem], [GetCurrentStructureItem], [StoreNoteEncrypted] and
/// [UpdateNoteStructure] and can throw the exceptions of them!
///
/// This returns a tuple of first the name of the source item and the new path of the parent folder for after the move!
/// If the path is empty, then that means, that it was moved to a top level folder!
class FinishMoveStructureItem extends UseCase<Tuple2<String, String>, FinishMoveStructureItemParams> {
  final GetCurrentStructureItem getCurrentStructureItem;
  final NoteStructureRepository noteStructureRepository;
  final GetOriginalStructureItem getOriginalStructureItem;
  final UpdateNoteStructure updateNoteStructure;
  final StoreNoteEncrypted storeNoteEncrypted;

  const FinishMoveStructureItem({
    required this.getCurrentStructureItem,
    required this.noteStructureRepository,
    required this.getOriginalStructureItem,
    required this.updateNoteStructure,
    required this.storeNoteEncrypted,
  });

  @override
  Future<Tuple2<String, String>> execute(FinishMoveStructureItemParams params) async {
    final StructureItem? sourceItem = noteStructureRepository.moveItemSrc;
    final StructureItem targetFolder = await getCurrentStructureItem.call(const NoParams());
    StructureItem? result;

    // important: this is needed to apply the move! (gets the reference to the root tree for the [targetFolder]).
    // so the top most parent is root instead of move!
    final StructureItem originalTarget = await getOriginalStructureItem.call(const NoParams());

    if (params.wasConfirmed == true &&
        hasNoChangesOrHasErrors(parent: targetFolder, child: sourceItem, originalTarget: originalTarget) == false) {
      Logger.verbose("confirmed the move");

      final StructureItem? oldCurrent = noteStructureRepository.currentItem;
      // important: get the original source item reference from the root tree
      noteStructureRepository.currentItem = sourceItem;
      final StructureItem originalSource = await getOriginalStructureItem.call(const NoParams());
      noteStructureRepository.currentItem = oldCurrent; // reset the current item again in case
      // something goes wrong

      result = await _moveChildToNewParent(child: originalSource, parent: originalTarget as StructureFolder); //update
      // the result so that it will be used to update the new current item
    } else {
      Logger.verbose("cancelled the move");
    }

    // important: update the note structure back to the old selected item from before the start of the move. This needs to
    // reset the current item and use the parent of the original item (sourceItem)! If the path was changed (by a
    // successful move), then this of course needs the item with the updated path (so result)!
    await updateNoteStructure.call(UpdateNoteStructureParams(originalItem: result ?? sourceItem, resetCurrentItem: true));

    Logger.info("${params.wasConfirmed ? "Finished" : "Cancelled"} the move for the item:\n$sourceItem\n to the new parent "
        "path ${targetFolder.path}");
    return Tuple2<String, String>(sourceItem?.name ?? "", originalTarget.isTopLevel ? "" : originalTarget.path);
  }

  Future<StructureItem> _moveChildToNewParent({required StructureItem child, required StructureFolder parent}) async {
    child.directParent!.removeChildRef(child);
    Logger.verbose("removed child from old parent ${child.directParent?.path}");

    StructureItem result = parent.addChild(child);
    Logger.verbose("added child to new parent ${parent.path}");

    if (result is StructureNote) {
      result = await _updateChildrenNote(result); // if note, then update time stamp and local stored path of itself and
      // update the result reference!
    } else if (result is StructureFolder) {
      final List<StructureNote> children = result.getAllNotes(); // if folder, then update it of the children notes
      for (final StructureNote note in children) {
        await _updateChildrenNote(note);
      }
    }

    return result;
  }

  Future<StructureItem> _updateChildrenNote(StructureNote note) async {
    final String newPath = note.path;
    if (newPath.isEmpty) {
      Logger.error("The path for the moved child note is empty:\n$note");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    // first update stored note
    final DateTime newTime = await storeNoteEncrypted
        .call(ChangeNoteEncryptedParams(noteId: note.id, decryptedName: newPath, decryptedContent: null));

    // then update note structure to replace the child in the parent and return the updated note reference if needed
    final StructureNote newNote = note.copyWith(newLastModified: newTime);
    note.directParent!.replaceChildRef(note, newNote);

    Logger.verbose("Updated a child note to the new path $newPath with time $newTime");
    return newNote;
  }

  bool hasNoChangesOrHasErrors(
      {required StructureItem parent, required StructureItem? child, required StructureItem originalTarget}) {
    if (child == null) {
      Logger.error("The source item is null for the move to the target folder:\n$parent");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    if (originalTarget.path == child.directParent!.path) {
      return true;
    }

    final bool isSamePathOrTopLevel = originalTarget.path == parent.path || (originalTarget.isTopLevel && parent.isTopLevel);

    if (parent is! StructureFolder ||
        parent.topMostParent.isMove == false ||
        originalTarget is! StructureFolder ||
        isSamePathOrTopLevel == false) {
      Logger.error("The current item is not a valid folder of the move selection:\n$parent");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    if (parent.path.startsWith(child.path)) {
      Logger.error("Tried to move a folder inside of a subfolder of itself:\n$parent");
      throw const ClientException(message: ErrorCodes.MOVED_INTO_SELF);
    }

    if (child is StructureFolder) {
      final StructureFolder? folderWithName = originalTarget.getDirectFolderByName(child.name, deepCopy: false);
      if (folderWithName != null) {
        Logger.error("There already is a folder with the name of the source inside of the target:\n$folderWithName");
        throw const ClientException(message: ErrorCodes.NAME_ALREADY_USED);
      }
    }

    return false;
  }
}

/// [wasConfirmed] is false if the cancel button was pressed instead of the confirm button.
class FinishMoveStructureItemParams {
  final bool wasConfirmed;

  const FinishMoveStructureItemParams({
    required this.wasConfirmed,
  });
}
