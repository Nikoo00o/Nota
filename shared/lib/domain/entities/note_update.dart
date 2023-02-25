import 'package:shared/core/enums/note_transfer_status.dart';
import 'package:shared/domain/entities/entity.dart';

/// The Information about a note transfer update
class NoteUpdate extends Entity {
  /// Even tho this is send from server to client, it needs to save the client id of the notes, because the client might
  /// not know the server id yet! Otherwise this will be the same as the [serverId] (also when a new note is created on
  /// the server side that the client does not have yet).
  ///
  /// The real client side generated ids will always be below 0
  final int clientId;

  /// This might be different than the [clientId] if the note was newly created on the client and did not exist on the
  /// server before. It will then be send on the transfer start, so the client can update its [clientId] on finish. Otherwise
  /// it will be the same as [clientId].
  ///
  /// Server ids will always be above 0
  final int serverId;

  /// This is only not null if the note did have a different file name on client, or server
  final String? newEncFileName;

  /// The new updated time stamp that should be set
  final DateTime newLastEdited;

  /// If Server, or client had a newer version of the file and the other one needs updating
  final NoteTransferStatus noteTransferStatus;

  NoteUpdate({
    required this.clientId,
    required this.serverId,
    required this.newEncFileName,
    required this.newLastEdited,
    required this.noteTransferStatus,
  }) : super(<String, Object?>{
          "clientId": clientId,
          "serverId": serverId,
          "newEncFileName": newEncFileName,
          "newLastEdited": newLastEdited,
          "noteTransferStatus": noteTransferStatus,
        });

  /// The notes had a different file name
  bool get wasFileNameChanged => newEncFileName != null;

  /// The more recent note had an empty file name, so it was deleted
  bool get wasFileDeleted => newEncFileName?.isEmpty ?? false;

  /// Compares 2 note update objects for sorting by the server id ascending
  static int compareByServerId(NoteUpdate first, NoteUpdate second) => first.serverId.compareTo(second.serverId);
}
