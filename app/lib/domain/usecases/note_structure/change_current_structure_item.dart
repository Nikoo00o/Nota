import 'dart:typed_data';
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

/// This renames the [NoteStructureRepository.currentItem] (note, or folder) and if it is a note, then it can also update
/// the content of this note. It does not move(changing parent path), or delete items!
///
/// Important: for files, you should only add [ChangeCurrentNoteParam.newContent] if the content really changed. This
/// should be verified by comparing a sha256 hash of the old and new content before calling this use case! Otherwise always
/// pass it as [null]!
///
/// If the [ChangeCurrentStructureItemParams.newName] is the same as the [StructureItem.name], then this use case will do
/// nothing (for files only if the content is also null).
/// If the name is empty, or if it contains the [StructureItem.delimiter] slash ("/") character, then it will throw
/// [ErrorCodes.INVALID_PARAMS]! This is also the case if the structure item type of the
/// [NoteStructureRepository.currentItem] does not match the [ChangeCurrentStructureItemParams] type.
///
/// If the [ChangeCurrentStructureItemParams.newName] is equal to one of the reserved names of the special folders, then
/// this will throw [ErrorCodes.NAME_ALREADY_USED]!
/// For folders this is also thrown if the new name is already taken by another folder with the same parent!
///
/// If the [NoteStructureRepository.currentItem] is not modifiable, or if it does not have a parent then this will throw
/// [ErrorCodes.CANT_BE_MODIFIED]. So it should not be set to [NoteStructureRepository.root], or [NoteStructureRepository.recent]!
///
/// This calls the use cases [GetOriginalStructureItem], [StoreNoteEncrypted] and [UpdateNoteStructure] and can throw the
/// exceptions of them!
class ChangeCurrentStructureItem extends UseCase<void, ChangeCurrentStructureItemParams> {
  final NoteStructureRepository noteStructureRepository;
  final GetOriginalStructureItem getOriginalStructureItem;
  final UpdateNoteStructure updateNoteStructure;
  final StoreNoteEncrypted storeNoteEncrypted;

  const ChangeCurrentStructureItem({
    required this.noteStructureRepository,
    required this.getOriginalStructureItem,
    required this.updateNoteStructure,
    required this.storeNoteEncrypted,
  });

  @override
  Future<void> execute(ChangeCurrentStructureItemParams params) async {
    final StructureItem item = await getOriginalStructureItem.call(const NoParams());
    late final StructureItem result;

    if (hasNoChangesOrHasErrors(params, item)) {
      Logger.debug("The params $params did not include any changes for the item:\n$item");
      return;
    }

    if (params is ChangeCurrentFolderParam && item is StructureFolder) {
      final StructureFolder? folderWithName = item.directParent!.getDirectFolderByName(params.newName, deepCopy: false);

      if (folderWithName != null) {
        Logger.error("There already is a folder with the name:\n$folderWithName");
        throw const ClientException(message: ErrorCodes.NAME_ALREADY_USED);
      }

      result = await _changeFolder(item, params.newName);
    } else if (params is ChangeCurrentNoteParam && item is StructureNote) {
      result = await _changeNote(item, params.newName, params.newContent, parentChanged: false);
    } else {
      Logger.error("The params $params did not have the same type as the item:\n$item");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    Logger.info("Changed the old item:\n$item\nto the new item:$result");
    // update the note structure at the end. important: also update the current item. without this a rename of a folder
    // would make the current item jump to the parent folder!
    await updateNoteStructure.call(UpdateNoteStructureParams(originalItem: result));
  }

  Future<StructureItem> _changeFolder(StructureFolder folder, String newName) async {
    // first update folder name
    final StructureFolder newFolder = folder.copyWith(newName: newName, changeParentOfChildren: true);
    folder.directParent!.replaceChildRef(folder, newFolder);
    Logger.verbose("changed folder name for ${folder.path} to $newName");

    // then update all of the new notes recursively
    final List<StructureNote> notes = newFolder.getAllNotes();
    for (final StructureNote note in notes) {
      await _changeNote(note, note.name, null, parentChanged: true);
    }

    return newFolder;
  }

  Future<StructureItem> _changeNote(StructureNote note, String newName, Uint8List? newContent,
      {required bool parentChanged}) async {
    String? newPath; // only not null if the path was changed
    if (newName != note.name) {
      newPath = note.directParent!.getPathForChildName(newName);
    } else if (parentChanged) {
      newPath = note.path;
    }

    // first update stored note
    final DateTime newTime = await storeNoteEncrypted
        .call(ChangeNoteEncryptedParams(noteId: note.id, decryptedName: newPath, decryptedContent: newContent));

    // then update note structure
    final StructureNote newNote = note.copyWith(newName: newName, newLastModified: newTime);
    note.directParent!.replaceChildRef(note, newNote);

    if (newPath == null) {
      Logger.verbose("Only updated note content for ${note.path} with time $newTime");
    } else {
      Logger.verbose("Updated the note path to $newPath with time $newTime and ${newContent == null ? "no" : "new"} "
          "content");
    }
    return newNote;
  }

  bool hasNoChangesOrHasErrors(ChangeCurrentStructureItemParams params, StructureItem item) {
    if (item.canBeModified == false || item.directParent == null) {
      Logger.error("The item can not be modified:\n$item");
      throw const ClientException(message: ErrorCodes.CANT_BE_MODIFIED);
    }
    StructureItem.throwErrorForName(params.newName);

    if (params.newName == item.name) {
      if (params is ChangeCurrentNoteParam && params.newContent != null) {
        return false;
      } else {
        return true;
      }
    }
    return false;
  }
}

abstract class ChangeCurrentStructureItemParams {
  /// The new name is always set and may not be empty!
  final String newName;

  const ChangeCurrentStructureItemParams({required this.newName});
}

class ChangeCurrentFolderParam extends ChangeCurrentStructureItemParams {
  const ChangeCurrentFolderParam({required super.newName});

  @override
  String toString() {
    return "newName=$newName";
  }
}

class ChangeCurrentNoteParam extends ChangeCurrentStructureItemParams {
  /// The new decrypted content of a file is optional and can be null if it should not be updated
  final Uint8List? newContent;

  const ChangeCurrentNoteParam({required super.newName, this.newContent});

  @override
  String toString() {
    return "newName=$newName, newContent=${newContent == null ? "none" : "added"}";
  }
}
