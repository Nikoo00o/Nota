import 'package:app/domain/entities/file_picker_result.dart';
import 'package:shared/data/models/model.dart';

class FilePickerResultModel extends FilePickerResult implements Model {
  static const String JSON_PATH = "JSON_PATH";
  static const String JSON_SIZE = "JSON_SIZE";
  static const String JSON_LAST_MODIFIED = "JSON_LAST_MODIFIED";

  FilePickerResultModel({required super.path, required super.size, required super.lastModified});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_PATH: path,
      JSON_SIZE: size,
      JSON_LAST_MODIFIED: lastModified.millisecondsSinceEpoch,
    };
  }

  factory FilePickerResultModel.fromJson(Map<String, dynamic> json) {
    return FilePickerResultModel(
      path: json[JSON_PATH] as String,
      size: json[JSON_SIZE] as int,
      lastModified: DateTime.fromMillisecondsSinceEpoch(json[JSON_LAST_MODIFIED] as int),
    );
  }
}
