import 'dart:io';
import 'package:app/domain/entities/note_content/note_content.dart';
import 'package:app/domain/repositories/external_file_repository.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

// todo: currently there is no test for this use case. and also this is currently not needed, because of a different
// pdf plugin!!!

/// This exports the decrypted content of the [SavePreviewPdfParams.pdfContent] to a temporary file and returns the
/// file path of that file, so it can be displayed inside of a pdf viewer widget.
///
/// Important: the file has to be deleted afterwards with the [PdfFileHandle.cleanup] function!
///
/// This can throw a [ClientException] with [ErrorCodes.INVALID_PARAMS]
class SavePreviewPdf extends UseCase<PdfFileHandle, SavePreviewPdfParams> {
  final ExternalFileRepository externalFileRepository;

  /// this is used for creating the temp file paths, so that multiple could be used at once and they don't override e
  /// ach other until they are cleaned up
  int _tempFileCounter = 0;

  static const String previewName = "preview";

  SavePreviewPdf({
    required this.externalFileRepository,
  });

  @override
  Future<PdfFileHandle> execute(SavePreviewPdfParams params) async {
    if (params.pdfContent.fileExtension != ".pdf") {
      Logger.error("the content ${params.pdfContent} did not have the pdf file extension");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    final String tempFolder = await externalFileRepository.getAbsoluteTempFilePath();
    final String path = "$tempFolder${Platform.pathSeparator}$previewName${_tempFileCounter++}.pdf";
    await externalFileRepository.saveExternalFile(path: path, bytes: params.pdfContent.content);
    Logger.debug("created temp pdf preview file at the path $path");
    return PdfFileHandle(filePath: path);
  }
}

class SavePreviewPdfParams {
  final NoteContentFileWrapper pdfContent;

  const SavePreviewPdfParams({
    required this.pdfContent,
  });
}

/// important: call [cleanup] after you used the file to delete it!
class PdfFileHandle {
  final String filePath;

  const PdfFileHandle({
    required this.filePath,
  });

  /// this deletes the temporary file located at the [filePath]
  void cleanup() {
    if (FileUtils.fileExists(filePath)) {
      FileUtils.deleteFile(filePath);
      Logger.debug("deleted temp pdf preview file at the path $filePath");
    } else {
      Logger.warn("pdf temp file at $filePath was already deleted before cleanup!");
    }
  }
}
