import 'package:server/domain/entities/server_account.dart';
import 'package:shared/domain/entities/entity.dart';
import 'package:shared/domain/entities/note_update.dart';

class NoteTransfer extends Entity {
  final ServerAccount serverAccount;

  final List<NoteUpdate> noteUpdates;

  NoteTransfer({
    required this.serverAccount,
    required this.noteUpdates,
  }) : super(<String, Object?>{
          "serverAccount": serverAccount,
          "noteUpdates": noteUpdates,
        });
}
