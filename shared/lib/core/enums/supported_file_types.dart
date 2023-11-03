import 'package:shared/core/enums/note_type.dart';

/// The supported file extensions for the [NoteType.FILE_WRAPPER], but without the "." of the extension string
enum SupportedFileTypes {
  /// special type: this will get converted to a default note!
  txt,
  jpg,
  jpeg,
  png,
  pdf;

  /// returns a matching supported file type. if the file extension starts with a ".", then it will get converted. so
  /// ".txt" and "txt" would both be supported
  factory SupportedFileTypes.fromString(String extension) {
    late String matcher;
    if (extension.startsWith(".")) {
      matcher = extension.substring(1);
    } else {
      matcher = extension;
    }
    return values.firstWhere((SupportedFileTypes element) => element.name == matcher);
  }

  @override
  String toString() {
    return name;
  }

  /// returns if the supported file types contain the file extension which may, or may not start with a ".", so "
  /// .txt", or "txt"
  static bool containsExtension(String extension) {
    late String matcher;
    if (extension.startsWith(".")) {
      matcher = extension.substring(1);
    } else {
      matcher = extension;
    }
    return values.any((SupportedFileTypes element) => element.toString() == matcher);
  }
}
