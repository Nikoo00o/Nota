import 'package:app/data/datasources/file_picker_data_source.dart.dart';

class FilePickerDataSourceMock extends FilePickerDataSource {
  /// used to set the result of [importFile]
  String? importPath;

  /// used to set the result of [exportFile]
  String? exportPath;

  @override
  Future<String?> importFile() async => importPath;

  @override
  Future<String?> exportFile({required String dialogTitle, required String fileName}) async => exportPath;
}
