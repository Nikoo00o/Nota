import 'package:shared/domain/entities/entity.dart';

/// The Information about a note which will be compared on server and client
class NoteInfo extends Entity {
  /// The unique id of the note for identification
  final int id;

  /// The base64 encoded file name of the note encrypted with the data key
  ///
  /// If this is empty, then that means that the note was deleted
  final String encFileName;

  /// The TimeStamp for when the note was edited the last time
  final DateTime lastEdited;

  NoteInfo({required this.id, required this.encFileName, required this.lastEdited})
      : super(<String, dynamic>{
          "id": id,
          "encFileName": encFileName,
          "lastEdited": lastEdited,
        });

  /// Creates a copy of this entity and changes the members to the parameters if they are not null.
  ///
  /// For Nullable parameter:
  /// If the Nullable Object itself is null, then it will not be used. Otherwise it's value is used to override the previous
  /// value (with either null, or a concrete value)
  @override
  NoteInfo copyWith({int? newId, String? newEncFileName, DateTime? newLastEdited}) {
    return NoteInfo(
      id: newId ?? id,
      encFileName: newEncFileName ?? encFileName,
      lastEdited: newLastEdited ?? lastEdited,
    );
  }

  /// Returns [true] if the [encFileName] of this note is empty!
  bool get isDeleted => encFileName.isEmpty;

  /// Compares 2 note info objects for sorting by id ascending
  static int compareById(NoteInfo first, NoteInfo second) => first.id.compareTo(second.id);
}
