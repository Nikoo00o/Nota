import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This deletes the [NoteStructureRepository.currentItem] (note, or folder) and navigates it to the parent folder!.
/// If the item is a folder, then it also removes all children.
///
/// If the [NoteStructureRepository.currentItem] is not modifiable, or if it does not have a parent then this will throw
/// [ErrorCodes.CANT_BE_MODIFIED]. So it should not be set to [NoteStructureRepository.root], or [NoteStructureRepository.recent]!
///
/// This calls the use cases [GetOriginalStructureItem], [StoreNoteEncrypted] and [UpdateNoteStructure] and can throw the
/// exceptions of them!
class DeleteCurrentStructureItem extends UseCase<void, NoParams> {
  final GetOriginalStructureItem getOriginalStructureItem;
  final UpdateNoteStructure updateNoteStructure;
  final StoreNoteEncrypted storeNoteEncrypted;

  const DeleteCurrentStructureItem({
    required this.getOriginalStructureItem,
    required this.updateNoteStructure,
    required this.storeNoteEncrypted,
  });

  @override
  Future<void> execute(NoParams params) async {
    final StructureItem item = await getOriginalStructureItem.call(const NoParams());
    final List<StructureNote> notesToDelete = List<StructureNote>.empty(growable: true);

    if (item.canBeModified == false || item.directParent == null) {
      Logger.error("The item can not be modified:\n$item");
      throw const ClientException(message: ErrorCodes.CANT_BE_MODIFIED);
    }

    if (item is StructureFolder) {
      notesToDelete.addAll(item.getAllNotes());
      Logger.debug("Removing folder ${item.name} from parent ${item.directParent!.path}");
      item.directParent!.removeChildRef(item);
    } else if (item is StructureNote) {
      notesToDelete.add(item);
      Logger.debug("Removing file ${item.name} from parent ${item.directParent!.path}");
      item.directParent!.removeChildRef(item);
    }

    for (final StructureNote note in notesToDelete) {
      Logger.debug("Deleting note ${note.path}");
      await storeNoteEncrypted.call(DeleteNoteEncryptedParams(noteId: note.id));
    }

    Logger.info("Deleted the following item:\n$item");
    // update the note structure at the end. the current item will automatically jump to the parent
    await updateNoteStructure.call(UpdateNoteStructureParams(originalItem: null));
  }
}
