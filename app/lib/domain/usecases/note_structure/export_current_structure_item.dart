import 'dart:typed_data';

import 'package:app/domain/entities/note_content/note_content.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/external_file_repository.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/services/translation_service.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This exports the decrypted content of the [NoteStructureRepository.currentItem] out of the app.
///
/// For default notes, it exports them into a txt file. File wrappers will be exported to their file extension.
/// Folders can currently not be exported.
///
/// This can throw a [ClientException] with [ErrorCodes.INVALID_PARAMS] and a [FileException] with
/// [ErrorCodes.FILE_NOT_FOUND]
///
/// This calls the use cases [GetOriginalStructureItem] and [LoadNoteContent] and can throw the exceptions of them!
class ExportCurrentStructureItem extends UseCase<void, NoParams> {
  final GetOriginalStructureItem getOriginalStructureItem;
  final LoadNoteContent loadNoteContent;
  final ExternalFileRepository externalFileRepository;
  final TranslationService translationService;

  const ExportCurrentStructureItem({
    required this.getOriginalStructureItem,
    required this.loadNoteContent,
    required this.externalFileRepository,
    required this.translationService,
  });

  @override
  Future<void> execute(NoParams params) async {
    final StructureItem item = await getOriginalStructureItem.call(const NoParams());
    if (item is StructureNote) {
      final NoteContent content =
          await loadNoteContent(LoadNoteContentParams(noteId: item.id, noteType: item.noteType));
      late String name;
      late Uint8List bytes;
      switch (item.noteType) {
        case NoteType.FOLDER:
          throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
        case NoteType.RAW_TEXT:
          name = "${item.name}.txt";
          bytes = content.text;
        case NoteType.FILE_WRAPPER:
          final NoteContentFileWrapper fileContent = content as NoteContentFileWrapper;
          name = "${item.name}${fileContent.fileExtension}";
          bytes = fileContent.content;
      }
      final String? path = await externalFileRepository.getExportFilePath(
        dialogTitle: translationService.translate("dialog.export.title"),
        fileName: name,
      );
      if (path != null) {
        await externalFileRepository.saveExternalFile(path: path, bytes: bytes);
        Logger.info("exported the item:\n$item\nto the path $path");
      } else {
        Logger.error("path for exported file is null");
        throw const FileException(message: ErrorCodes.FILE_NOT_FOUND);
      }
    } else if (item is StructureFolder) {
      Logger.error("exporting folders is currently not supported");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
  }
}
