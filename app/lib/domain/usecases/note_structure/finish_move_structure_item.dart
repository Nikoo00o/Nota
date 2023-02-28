import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/start_move_structure_item.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

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
/// This calls the use cases [GetOriginalStructureItem], [GetCurrentStructureItem] and [UpdateNoteStructure] and can throw the
/// exceptions of them!
class FinishMoveStructureItem extends UseCase<void, FinishMoveStructureItemParams> {
  final GetCurrentStructureItem getCurrentStructureItem;
  final NoteStructureRepository noteStructureRepository;
  final GetOriginalStructureItem getOriginalStructureItem;
  final UpdateNoteStructure updateNoteStructure;

  const FinishMoveStructureItem({
    required this.getCurrentStructureItem,
    required this.noteStructureRepository,
    required this.getOriginalStructureItem,
    required this.updateNoteStructure,
  });

  @override
  Future<void> execute(FinishMoveStructureItemParams params) async {
    final StructureItem? sourceItem = noteStructureRepository.moveItemSrc;
    final StructureItem targetFolder = await getCurrentStructureItem.call(const NoParams());

    // important: this is needed to apply the move! (gets the reference to the root tree)
    final StructureItem originalTarget = await getOriginalStructureItem.call(const NoParams());

    noteStructureRepository.moveItemSrc = null; // always reset and cancel the move first before throwing errors
    noteStructureRepository.currentItem = noteStructureRepository.root; // default way is to navigate to root on errors

    if (params.wasConfirmed == true &&
        hasNoChangesOrHasErrors(parent: targetFolder, child: sourceItem, originalTarget: originalTarget) == false) {
      Logger.verbose("confirmed the move");

      // important: get the original source item reference from the root tree
      noteStructureRepository.currentItem = sourceItem;
      final StructureItem originalSource = await getOriginalStructureItem.call(const NoParams());
      noteStructureRepository.currentItem = noteStructureRepository.root; // reset the current item again in case
      // something goes wrong

      originalSource.directParent!.removeChildRef(originalSource);
      Logger.verbose("removed child from old parent ${originalSource.directParent?.path}");
      (originalTarget as StructureFolder).addChild(originalSource);
      Logger.verbose("removed child to new parent ${originalTarget.path}");
    } else {
      Logger.verbose("cancelled the move");
    }

    // important: update the note structure back to the old selected item from before the start of the move. This needs to
    // reset the current item and use the parent of the original item (sourceItem)!
    await updateNoteStructure.call(UpdateNoteStructureParams(originalItem: sourceItem, resetCurrentItem: true));

    Logger.info("${params.wasConfirmed ? "Finished" : "Cancelled"} the move for the item:\n$sourceItem\n to the new parent "
        "path ${targetFolder.path}");
  }

  bool hasNoChangesOrHasErrors(
      {required StructureItem parent, required StructureItem? child, required StructureItem originalTarget}) {
    if (child == null) {
      Logger.error("The source item is null for the move to the target folder:\n$parent");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    if (parent.path == child.directParent!.path) {
      return true;
    }

    if (parent is! StructureFolder ||
        parent.topMostParent.isMove == false ||
        originalTarget is! StructureFolder ||
        originalTarget.path != parent.path) {
      Logger.error("The current item is not a valid folder of the move selection:\n$parent");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    if (child is StructureFolder) {
      final StructureFolder? folderWithName = parent.getDirectFolderByName(child.name, deepCopy: false);
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
