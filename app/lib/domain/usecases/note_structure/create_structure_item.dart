import 'dart:typed_data';

import 'package:app/core/config/app_config.dart';
import 'package:app/domain/entities/file_picker_result.dart';
import 'package:app/domain/entities/note_content/note_content.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/external_file_repository.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/enums/supported_file_types.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/file_utils.dart';
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
/// The new name should be retrieved with a dialog from the ui before calling this use case. This use case can also
/// open a dialog for [NoteType.FILE_WRAPPER] so that the user can select the file to be imported into the app.
/// that can an throw [FileException] with [ErrorCodes.FILE_NOT_FOUND] if no file was selected, or
/// [ErrorCodes.FILE_NOT_SUPPORTED] if a file with no supported type of [SupportedFileTypes] was selected
class CreateStructureItem extends UseCase<void, CreateStructureItemParams> {
  final NoteStructureRepository noteStructureRepository;
  final GetOriginalStructureItem getOriginalStructureItem;
  final UpdateNoteStructure updateNoteStructure;
  final StoreNoteEncrypted storeNoteEncrypted;
  final AppConfig appConfig;
  final ExternalFileRepository externalFileRepository;

  const CreateStructureItem({
    required this.noteStructureRepository,
    required this.getOriginalStructureItem,
    required this.updateNoteStructure,
    required this.storeNoteEncrypted,
    required this.appConfig,
    required this.externalFileRepository,
  });

  @override
  Future<void> execute(CreateStructureItemParams params) async {
    final StructureItem currentFolder = await getOriginalStructureItem.call(const NoParams());
    late final StructureItem newItem;

    if (noteStructureRepository.currentItem!.topMostParent.isRecent && params.noteType == NoteType.FOLDER) {
      Logger.error("The current item is inside of recent and the target is to create a folder");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    if (currentFolder is! StructureFolder) {
      Logger.error("The current item is not a folder:\n$currentFolder");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    StructureItem.throwErrorForName(params.name);

    newItem = switch (params.noteType) {
      NoteType.FOLDER => await _createFolder(currentFolder, params.name),
      NoteType.RAW_TEXT => await _createNoteType(
          currentFolder,
          params.name,
          NoteContent.saveFile(decryptedContent: <int>[], noteType: params.noteType),
        ),
      NoteType.FILE_WRAPPER => await _createNoteType(currentFolder, params.name, await _createFileWrapper(params)),
    };

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
      compareCaseSensitive: appConfig.searchCaseSensitive,
    ));
  }

  Future<StructureItem> _createNoteType(StructureFolder currentFolder, String newName, NoteContent noteContent) async {
    // first get new note client id
    final int noteId = await noteStructureRepository.getNewClientNoteCounter();

    // then create note in local storage
    final DateTime timeStamp = await storeNoteEncrypted.call(CreateNoteEncryptedParams(
      noteId: noteId,
      decryptedName: currentFolder.getPathForChildName(newName),
      decryptedContent: noteContent,
    ));

    // then update note in structure
    return currentFolder.addChild(StructureNote(
      name: newName,
      directParent: null,
      canBeModified: true,
      id: noteId,
      lastModified: timeStamp,
      noteType: noteContent.noteType,
    ));
  }

  /// important: for .txt files, this will just import them into a default note and not create a file wrapper!!
  ///
  /// Can throw [FileException] with [ErrorCodes.FILE_NOT_FOUND] if no file was selected
  Future<NoteContent> _createFileWrapper(CreateStructureItemParams params) async {
    FilePickerResult? importedFile;
    if (params is CreateStructureItemParamsFromDroppedFile) {
      importedFile = await externalFileRepository.getImportFileInfo(pathOverride: params.path);
    } else {
      importedFile = await externalFileRepository.getImportFileInfo();
    }
    if (importedFile == null) {
      Logger.error("the imported file is null for ${params.name}");
      throw const FileException(message: ErrorCodes.FILE_NOT_FOUND);
    }

    final Uint8List bytes = await externalFileRepository.loadExternalFileCompressed(
      path: importedFile.path,
      compression: appConfig.imageCompressionLevel,
    );

    if (importedFile.extension == ".txt") {
      Logger.verbose("imported a note file from text ${params.name}");
      return NoteContent.saveFile(decryptedContent: bytes, noteType: NoteType.RAW_TEXT);
    } else {
      Logger.verbose("imported the new file ${params.name}");
      return NoteContent.saveFile(
        decryptedContent: bytes,
        noteType: NoteType.FILE_WRAPPER,
        fileWrapperParams: FileWrapperParams(fileInfo: importedFile),
      );
    }
  }
}

class CreateStructureItemParams {
  final String name;

  /// What kind of note this is. this can also be a folder
  final NoteType noteType;

  const CreateStructureItemParams({
    required this.name,
    required this.noteType,
  });

  /// creates a raw text note
  const CreateStructureItemParams.note({
    required String name,
  }) : this(name: name, noteType: NoteType.RAW_TEXT);

  const CreateStructureItemParams.folder({
    required String name,
  }) : this(name: name, noteType: NoteType.FOLDER);

  const CreateStructureItemParams.fileWrapper({
    required String name,
  }) : this(name: name, noteType: NoteType.FILE_WRAPPER);
}

/// special case when the user drag and drops a file into the note selection of the app (so no dialog to import a
/// file is opened)
class CreateStructureItemParamsFromDroppedFile extends CreateStructureItemParams {
  /// the path to the file to be imported into this
  final String path;

  CreateStructureItemParamsFromDroppedFile({
    required this.path,
  }) : super.fileWrapper(name: FileUtils.getFileName(path));
}
