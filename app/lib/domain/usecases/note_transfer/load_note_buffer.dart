import 'dart:convert';
import 'dart:typed_data';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_transfer/save_note_buffer.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This restores the previously saved note buffer from [SaveNoteBuffer] after the lock screen!
///
/// This can return null if nothing was saved!
///
/// This can throw the exceptions of [GetLoggedInAccount]!
class LoadNoteBuffer extends UseCase<String?, NoParams> {
  final GetLoggedInAccount getLoggedInAccount;
  final NoteTransferRepository noteTransferRepository;

  const LoadNoteBuffer({required this.getLoggedInAccount, required this.noteTransferRepository});

  @override
  Future<String?> execute(NoParams params) async {
    if (noteTransferRepository.encryptedNoteBufferCache == null) {
      Logger.verbose("encrypted note buffer cache is empty");
      return null;
    } else {
      Logger.verbose("loading encrypted note buffer cache");
      final ClientAccount account = await getLoggedInAccount.call(const NoParams());
      final Uint8List decryptedBytes = await SecurityUtilsExtension.decryptBytesAsync(
          noteTransferRepository.encryptedNoteBufferCache!, account.decryptedDataKey!);
      return utf8.decode(decryptedBytes);
    }
  }
}
