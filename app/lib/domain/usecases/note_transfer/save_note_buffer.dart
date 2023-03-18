import 'dart:convert';
import 'dart:typed_data';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_transfer/load_note_buffer.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This is used to cache the current note content (if there were any unsaved changes) which is being edited when the app
/// pauses. It will then be restored after the lock screen with [LoadNoteBuffer]!
///
/// This can throw the exceptions of [GetLoggedInAccount]!
class SaveNoteBuffer extends UseCase<void, SaveNoteBufferParams> {
  final GetLoggedInAccount getLoggedInAccount;
  final NoteTransferRepository noteTransferRepository;

  const SaveNoteBuffer({required this.getLoggedInAccount, required this.noteTransferRepository});

  @override
  Future<void> execute(SaveNoteBufferParams params) async {
    if (params.content == null) {
      Logger.verbose("reset encrypted note buffer cache");
      noteTransferRepository.encryptedNoteBufferCache = null;
    } else {
      Logger.verbose("updated encrypted note buffer cache");
      final ClientAccount account = await getLoggedInAccount.call(const NoParams());
      final Uint8List decryptedBytes = Uint8List.fromList(utf8.encode(params.content!));
      noteTransferRepository.encryptedNoteBufferCache =
          await SecurityUtilsExtension.encryptBytesAsync(decryptedBytes, account.decryptedDataKey!);
    }
  }
}

class SaveNoteBufferParams {
  /// The raw decrypted note content from the gui. this can be null to reset the cached buffer!
  final String? content;

  const SaveNoteBufferParams({required this.content});
}
