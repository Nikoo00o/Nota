import 'package:shared/core/enums/note_type.dart';

/// The supported file extensions for the [NoteType.FILE_WRAPPER]
enum SupportedFileTypes {
  jpg,
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
