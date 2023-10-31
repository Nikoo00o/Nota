import 'package:server/domain/entities/server_account.dart';
import 'package:shared/domain/entities/entity.dart';
import 'package:shared/domain/entities/note_update.dart';

class NoteTransfer extends Entity {
  final ServerAccount serverAccount;

  final List<NoteUpdate> noteUpdates;

  /// the content for the notes of these server ids had the same hash on server and client, so they are not uploaded
  /// from the client to the server (download is ignored here)
  final List<int> serverIdsWithEqualHash = List<int>.empty(growable: true);

  NoteTransfer({
    required this.serverAccount,
    required this.noteUpdates,
  }) : super(<String, Object?>{
          "serverAccount": serverAccount,
          "noteUpdates": noteUpdates,
        });
}
