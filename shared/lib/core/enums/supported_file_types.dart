import 'package:shared/core/enums/note_type.dart';

/// The supported file extensions for the [NoteType.FILE_WRAPPER], but without the "." of the extension string
enum SupportedFileTypes {
  /// special type: this will get converted to a default note!
  txt,
  jpg,
  jpeg,
  png,
  pdf;

  factory SupportedFileTypes.fromString(String data) {
    return values.firstWhere((SupportedFileTypes element) => element.name == data);
  }

  @override
  String toString() {
    return name;
  }
}
