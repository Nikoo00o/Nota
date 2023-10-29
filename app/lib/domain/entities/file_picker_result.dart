import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/domain/entities/entity.dart';

/// The result of a local file that has been picked to be imported into the app. This only contains information and
/// not the actual content of the local file!
class FilePickerResult extends Entity {
  final String path;

  final int size;

  final DateTime lastModified;

  FilePickerResult({required this.path, required this.size, required this.lastModified})
      : super(<String, dynamic>{
          "path": path,
          "size": size,
          "lastModified": lastModified.toIso8601String(),
        });

  /// last part of path
  String get extension => FileUtils.getExtension(path);
}
