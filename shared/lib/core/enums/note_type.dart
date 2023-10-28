import 'package:shared/core/enums/supported_file_types.dart';

/// The type of a note (raw text, a folder, or some other special notes). "note_content.dart" inside of the app
/// project also needs to be adjusted with more sub classes if new types are added here!
enum NoteType {
  /// default text only notes
  RAW_TEXT,

  /// special case that is not stored, but instead used for creating notes and folders
  FOLDER,

  /// a note that acts as a wrapper for a file like an image, or a pdf, etc of [SupportedFileTypes]
  FILE_WRAPPER;
}
