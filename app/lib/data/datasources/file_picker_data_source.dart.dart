import 'package:file_picker/file_picker.dart';
import 'package:shared/core/enums/supported_file_types.dart';
import 'package:shared/core/utils/file_utils.dart';

/// This is a wrapper around the file picker package to import/export files to/from the app!
abstract class FilePickerDataSource {
  /// this opens a platform specific dialog where the user can select a path to a file of the [SupportedFileTypes]
  /// which should be imported into  the app
  Future<String?> importFile();

  /// this opens a platform specific dialog where the user can select a path to a folder where the [fileName]
  /// file should be exported to
  Future<String?> exportFile({required String dialogTitle, required String fileName});
}

class FilePickerDataSourceImpl extends FilePickerDataSource {
  @override
  Future<String?> importFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: SupportedFileTypes.values.map((SupportedFileTypes e) => e.toString()).toList(),
    );
    return result?.files.single.path;
  }

  @override
  Future<String?> exportFile({required String dialogTitle, required String fileName}) => FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: <String>[FileUtils.getExtension(fileName).substring(1)],
      );
}
