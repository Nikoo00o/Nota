import 'dart:io';
import 'dart:typed_data';

import 'package:app/data/datasources/file_picker_data_source.dart.dart';
import 'package:app/data/models/file_picker_result_model.dart';
import 'package:app/domain/entities/file_picker_result.dart';
import 'package:app/domain/repositories/external_file_repository.dart';
import 'package:image/image.dart' as img;
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';

class ExternalFileRepositoryImpl extends ExternalFileRepository {
  final FilePickerDataSource filePickerDataSource;

  ExternalFileRepositoryImpl({required this.filePickerDataSource});

  @override
  Future<FilePickerResult?> getImportFileInfo() async {
    final String? path = await filePickerDataSource.importFile();
    if (path != null) {
      final File file = File(path);
      if (await file.exists()) {
        final FilePickerResult result = FilePickerResultModel(
          path: path,
          size: await file.length(),
          lastModified: await file.lastModified(),
        );
        Logger.verbose("Got imported file info: $result");
        return result;
      }
    }
  }

  @override
  Future<String?> getExportFilePath({required String dialogTitle, required String fileName}) async {
    final String? path = await filePickerDataSource.exportFile(dialogTitle: dialogTitle, fileName: fileName);
    Logger.verbose("Got exported file path: $path");
    return path;
  }

  @override
  Future<Uint8List> loadExternalFileCompressed({required String path, required int compression}) async {
    Uint8List? bytes = await FileUtils.readFileAsBytes(path);
    if (bytes == null) {
      Logger.error("external file $path can not be found");
      throw const FileException(message: ErrorCodes.FILE_NOT_FOUND);
    }
    if (compression > 9) {
      Logger.error("compression $compression for external file is too high");
      throw const FileException(message: ErrorCodes.FILE_NOT_FOUND);
    }

    final String ext = FileUtils.getExtension(path);
    final bool isPng = ext == ".png";
    final bool isJpg = ext == ".jpg" || ext == ".jpeg";

    if (compression > 0 && (isPng || isJpg)) {
      final img.Decoder? decoder = img.findDecoderForNamedImage(path);
      final img.Image? raw = decoder?.decode(bytes);
      if (raw != null) {
        if (isPng) {
          bytes = img.encodePng(raw, level: compression);
        } else if (isJpg) {
          bytes = img.encodeJpg(raw, quality: 100 - compression * 10);
        }
      }
    }

    Logger.verbose("Loaded external file $path");
    return bytes;
  }

  @override
  Future<void> saveExternalFile({required String path, required List<int> bytes}) async {
    await FileUtils.writeFileAsBytes(path, bytes);
    Logger.verbose("Saved external file $path");
  }
}
