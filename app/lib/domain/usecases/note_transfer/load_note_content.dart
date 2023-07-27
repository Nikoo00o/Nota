import 'dart:io';
import 'dart:typed_data';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/entities/note_content.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This decrypts and returns the content of a note and it can throw a [FileException] with [ErrorCodes.FILE_NOT_FOUND] if
/// the note was not found.
///
/// This can throw the exceptions of [GetLoggedInAccount]!
class LoadNoteContent extends UseCase<NoteContent, LoadNoteContentParams> {
  final GetLoggedInAccount getLoggedInAccount;
  final NoteTransferRepository noteTransferRepository;

  const LoadNoteContent({required this.getLoggedInAccount, required this.noteTransferRepository});

  @override
  Future<NoteContent> execute(LoadNoteContentParams params) async {
    final ClientAccount account = await getLoggedInAccount.call(const NoParams());

    final Uint8List encryptedBytes = await noteTransferRepository.loadEncryptedNote(noteId: params.noteId);
    final Uint8List uncompressedBytes = await _decryptAndDecompressBytes(encryptedBytes, account);

    Logger.debug("Decrypted and returned note content for note ${params.noteId}");
    return NoteContent.loadFile(bytes: uncompressedBytes, noteType: params.noteType);
  }

  Future<Uint8List> _decryptAndDecompressBytes(Uint8List encryptedBytes, ClientAccount account) async {
    final Uint8List decryptedBytes =
        await SecurityUtilsExtension.decryptBytesAsync(encryptedBytes, account.decryptedDataKey!);
    return gzip.decode(decryptedBytes) as Uint8List;
  }
}

class LoadNoteContentParams {
  final int noteId;
  final NoteType noteType;

  const LoadNoteContentParams({required this.noteId, required this.noteType});
}
