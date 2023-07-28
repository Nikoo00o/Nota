/// The type of a note (raw text, a folder, or some other special notes). "note_content.dart" inside of the app
/// project also needs to be adjusted with more sub classes if new types are added here!
enum NoteType {
  /// default text only notes
  RAW_TEXT,

  /// special case that is not stored, but instead used for creating notes and folders
  FOLDER;
}
