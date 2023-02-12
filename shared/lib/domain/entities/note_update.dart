import 'package:shared/core/enums/note_transfer_status.dart';
import 'package:shared/domain/entities/entity.dart';

/// The Information about a note transfer update
class NoteUpdate extends Entity {
  /// Even tho this is send from server to client, it needs to save the client id of the notes, because the client might
  /// not know the server id yet!
  final int clientId;

  /// This might be different than the [clientId] if the note was newly created on the client and did not exist on the
  /// server before. It will then be send on the transfer finish. Otherwise it will be the same as [clientId]
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
  }) : super(<String, dynamic>{
          "clientId": clientId,
          "serverId": serverId,
          "newEncFileName": newEncFileName,
          "newLastEdited": newLastEdited,
          "noteTransferStatus": noteTransferStatus,
        });

  bool get wasFileNameChanged => newEncFileName != null;

  bool get wasFileDeleted => newEncFileName?.isEmpty ?? false;
}
