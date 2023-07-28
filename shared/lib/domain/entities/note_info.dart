import 'package:shared/core/enums/note_type.dart';
import 'package:shared/domain/entities/entity.dart';

// ignore_for_file: hash_and_equals

/// The Information about a note which will be compared on server and client
class NoteInfo extends Entity {
  /// The unique id of the note for identification
  final int id;

  /// The base64 encoded file name of the note encrypted with the data key.
  ///
  /// If this is empty, then that means that the note was deleted.
  ///
  /// The file name contains the virtual path of the note structure as well as the name of the note! It does not contain a
  /// file extension!
  final String encFileName;

  /// The TimeStamp for when the note was edited the last time
  final DateTime lastEdited;

  /// what kind of note this is
  final NoteType noteType;

  NoteInfo({required this.id, required this.encFileName, required this.lastEdited, required this.noteType})
      : super(<String, Object?>{
          "id": id,
          "encFileName": encFileName,
          "lastEdited": lastEdited,
          "noteType": noteType,
        });

  /// Creates a copy of this entity and changes the members to the parameters if they are not null.
  ///
  /// For Nullable parameter:
  /// If the Nullable Object itself is null, then it will not be used. Otherwise it's value is used to override the previous
  /// value (with either null, or a concrete value)
  ///
  /// Needs to be overridden in the model as well!
  NoteInfo copyWith({int? newId, String? newEncFileName, DateTime? newLastEdited, NoteType? newNoteType}) {
    return NoteInfo(
      id: newId ?? id,
      encFileName: newEncFileName ?? encFileName,
      lastEdited: newLastEdited ?? lastEdited,
      noteType: newNoteType ?? noteType,
    );
  }

  /// Override the default operator==, because note info models should be able to be equal to note info objects (so
  /// runtimetype is not compared here!)
  @override
  bool operator ==(Object other) => compareWithoutRuntimeType(other);

  /// Returns [true] if the [encFileName] of this note is empty!
  bool get isDeleted => encFileName.isEmpty;

  /// Compares 2 note info objects for sorting by id ascending
  static int compareById(NoteInfo first, NoteInfo second) => first.id.compareTo(second.id);
}
