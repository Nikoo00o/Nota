import 'dart:typed_data';
import 'package:app/domain/entities/file_picker_result.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/supported_file_types.dart';
import 'package:shared/core/exceptions/exceptions.dart';

abstract class ExternalFileRepository {
  /// lets the user select a file of [SupportedFileTypes] for which all information will be returned. returns null
  /// if the user has not selected a file
  ///
  /// If [pathOverride] is used, then the dialog will not be opened for the user to select the input file.
  ///
  /// This returns a [FileException] with [ErrorCodes.FILE_NOT_SUPPORTED] if a file with no supported extension from
  /// [SupportedFileTypes] was selected
  Future<FilePickerResult?> getImportFileInfo({String? pathOverride});

  /// lets the user select a path where the [fileName] should be exported to. returns null if the user has not
  /// selected a destination. the file name may contain an extension, but it may also be without one, because its
  /// just a suggestion
  ///
  /// This returns a [FileException] with [ErrorCodes.FILE_NOT_SUPPORTED] if a file with no supported extension from
  /// [SupportedFileTypes] was selected
  Future<String?> getExportFilePath({required String dialogTitle, required String fileName});

  /// can throw an [FileException] with [ErrorCodes.FILE_NOT_FOUND]
  ///
  /// This will compress jpg, jpeg and png images depending on the [compression] level (0 - 9):
  /// 0 means no compression and 9 is the highest compression. default would be 6
  ///
  /// Other files will not be compressed
  Future<Uint8List> loadExternalFileCompressed({required String path, required int compression});

  /// can throw an [FileException] with [ErrorCodes.FILE_NOT_FOUND]
  Future<void> saveExternalFile({required String path, required List<int> bytes});
}
