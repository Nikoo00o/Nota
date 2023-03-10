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

/// This creates a new structure item inside of the [NoteStructureRepository.currentItem] folder. It can create either a
/// folder, or a note (which would also get a new client note id and an empty content). It will then navigate to the newly
/// created item!
///
/// If the [NoteStructureRepository.currentItem] is not a [StructureFolder], then this will throw [ErrorCodes.INVALID_PARAMS].
/// If the current item is [NoteStructureRepository.recent], or a folder in recent and the [CreateStructureItemParams.isFolder]
/// is true, then it will throw [ErrorCodes.INVALID_PARAMS] as well.
///
/// If the [CreateStructureItemParams.name] is empty, or if it contains the [StructureItem.delimiter] slash ("/")
/// character, then it will throw [ErrorCodes.INVALID_PARAMS]!
///
/// If the [CreateStructureItemParams.name] is equal to one of the reserved names of the special folders, then
/// this will throw [ErrorCodes.NAME_ALREADY_USED]!
/// If [CreateStructureItemParams.isFolder] is true, then this is also thrown if the new name is already taken by another
/// folder with the same parent!
///
/// This calls the use cases [GetOriginalStructureItem], [StoreNoteEncrypted] and [UpdateNoteStructure] and can throw the
/// exceptions of them!
///
/// The new name should be retrieved with a dialog from the ui before calling this use case.
class CreateStructureItem extends UseCase<void, CreateStructureItemParams> {
  final NoteStructureRepository noteStructureRepository;
  final GetOriginalStructureItem getOriginalStructureItem;
  final UpdateNoteStructure updateNoteStructure;
  final StoreNoteEncrypted storeNoteEncrypted;

  const CreateStructureItem({
    required this.noteStructureRepository,
    required this.getOriginalStructureItem,
    required this.updateNoteStructure,
    required this.storeNoteEncrypted,
  });

  @override
  Future<void> execute(CreateStructureItemParams params) async {
    final StructureItem currentFolder = await getOriginalStructureItem.call(const NoParams());
    late final StructureItem newItem;

    if (currentFolder is! StructureFolder) {
      Logger.error("THe current item is not a folder:\n$currentFolder");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    StructureItem.throwErrorForName(params.name);

    if (params.isFolder) {
      newItem = await _createFolder(currentFolder, params.name);
    } else {
      newItem = await _createNote(currentFolder, params.name);
    }

    Logger.info("Created the new item:\n$newItem");
    // update the note structure at the end with the new item, so that the current item will navigate to it.
    await updateNoteStructure.call(UpdateNoteStructureParams(originalItem: newItem));
  }

  Future<StructureItem> _createFolder(StructureFolder currentFolder, String newName) async {
    final StructureFolder? folderWithName = currentFolder.getDirectFolderByName(newName, deepCopy: false);

    if (folderWithName != null) {
      Logger.error("There already is a folder with the name:\n$folderWithName");
      throw const ClientException(message: ErrorCodes.NAME_ALREADY_USED);
    }

    if (currentFolder.isRecent || currentFolder.topMostParent.isRecent) {
      Logger.error("The current item is recent, or a folder in recent when trying to create a folder:\n$currentFolder");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS); // cant create folder in recent dir
    }

    // the directParent will be set by addChild
    return currentFolder.addChild(StructureFolder(
      name: newName,
      directParent: null,
      canBeModified: true,
      children: List<StructureItem>.empty(growable: true),
      sorting: currentFolder.sorting,
      changeParentOfChildren: false,
    ));
  }

  Future<StructureItem> _createNote(StructureFolder currentFolder, String newName) async {
    // first get new note client id
    final int noteId = await noteStructureRepository.getNewClientNoteCounter();

    // then create note in local storage
    final DateTime timeStamp = await storeNoteEncrypted.call(CreateNoteEncryptedParams(
      noteId: noteId,
      decryptedName: currentFolder.getPathForChildName(newName),
      decryptedContent: Uint8List(0),
    ));

    // then update note in structure
    return currentFolder.addChild(StructureNote(
      name: newName,
      directParent: null,
      canBeModified: true,
      id: noteId,
      lastModified: timeStamp,
    ));
  }
}

class CreateStructureItemParams {
  final String name;

  /// If this is false, then the newly created item will be a note.
  final bool isFolder;

  const CreateStructureItemParams({
    required this.name,
    required this.isFolder,
  });

  const CreateStructureItemParams.note({
    required String name,
  }) : this(name: name, isFolder: false);

  CreateStructureItemParams.folder({
    required String name,
  }) : this(name: name, isFolder: true);
}
