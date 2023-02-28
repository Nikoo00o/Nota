import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/account/save_account.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/usecases/usecase.dart';

// ignore_for_file: prefer_initializing_formals

/// This encrypts the contents of the params and stores it inside of the account and note repository locally, so that the
/// note will be updated! This updates the account and the note file locally!
///
/// It can either create, delete, or rename a note, or change the content of a note and returns a new [DateTime] time stamp
/// as the last modification date!
///
/// This can throw a [FileException] with [ErrorCodes.FILE_NOT_FOUND] if the note was not found, or if it was already
/// contained when creating a new note.
///
/// It can also trow a [ClientException] with [ErrorCodes.INVALID_PARAMS] if change/create params were used with an
/// empty filename, or if change was used with no params at all!
///
/// This can throw the exceptions of [GetLoggedInAccount]!
class StoreNoteEncrypted extends UseCase<DateTime, StoreNoteEncryptedParams> {
  final GetLoggedInAccount getLoggedInAccount;
  final SaveAccount saveAccount;
  final NoteTransferRepository noteTransferRepository;

  const StoreNoteEncrypted({
    required this.getLoggedInAccount,
    required this.saveAccount,
    required this.noteTransferRepository,
  });

  @override
  Future<DateTime> execute(StoreNoteEncryptedParams params) async {
    final DateTime now = DateTime.now();
    final ClientAccount account = await getLoggedInAccount.call(const NoParams());

    if (params is DeleteNoteEncryptedParams) {
      await _delete(params, account, now);
      Logger.info("Deleted note ${params.noteId}");
    } else if (params is CreateNoteEncryptedParams) {
      await _create(params, account, now);
      Logger.info("Created note ${params.noteId}");
    } else if (params is ChangeNoteEncryptedParams) {
      await _change(params, account, now);
      Logger.info("Changed note ${params.noteId}");
    }

    await saveAccount.call(const NoParams()); // always save changes to the account to the local storage at the end!
    return now;
  }

  Future<void> _delete(StoreNoteEncryptedParams params, ClientAccount account, DateTime now) async {
    if (params.decryptedContent?.isNotEmpty ?? false) {
      Logger.warn("Delete called with content which is not empty");
    }

    final bool containedNote = account.changeNote(noteId: params.noteId, newEncFileName: "", newLastEdited: now);
    if (!containedNote) {
      Logger.error("The note file to be deleted was not contained in the account");
      throw const FileException(message: ErrorCodes.FILE_NOT_FOUND);
    }

    final bool fileDeleted = await noteTransferRepository.deleteNote(noteId: params.noteId);
    if (!fileDeleted) {
      Logger.warn("The note file to be deleted did not exist");
    }
  }

  Future<void> _create(StoreNoteEncryptedParams params, ClientAccount account, DateTime now) async {
    final bool containsNote = account.getNoteById(params.noteId) != null;
    if (containsNote) {
      Logger.error("The note file to be created with the id ${params.noteId} was already contained in the account");
      throw const FileException(message: ErrorCodes.FILE_NOT_FOUND);
    }

    if (params.decryptedContent!.isEmpty) {
      Logger.debug("Create called with an empty content");
    }

    final String? encryptedFileName = await _encryptFileName(params.decryptedName, account); // should not be null

    account.noteInfoList.add(NoteInfo(
      id: params.noteId,
      encFileName: encryptedFileName!,
      lastEdited: now,
    ));

    await noteTransferRepository.storeEncryptedNote(
      noteId: params.noteId,
      encryptedBytes: await _encryptAndCompressContent(params.decryptedContent!, account),
    );
  }

  Future<void> _change(StoreNoteEncryptedParams params, ClientAccount account, DateTime now) async {
    if (params.decryptedContent == null && params.decryptedName == null) {
      Logger.warn("Change called with no content and no file name");
    }

    final bool containedNote = account.changeNote(
      noteId: params.noteId,
      newEncFileName: await _encryptFileName(params.decryptedName, account),
      newLastEdited: now,
    );

    if (!containedNote) {
      Logger.error("The note file to be changed was not contained in the account");
      throw const FileException(message: ErrorCodes.FILE_NOT_FOUND);
    }

    if (params.decryptedContent != null) {
      await noteTransferRepository.storeEncryptedNote(
        noteId: params.noteId,
        encryptedBytes: await _encryptAndCompressContent(params.decryptedContent!, account),
      );
    }
  }

  Future<String?> _encryptFileName(String? fileName, ClientAccount account) async {
    if (fileName == null) {
      return null;
    }
    return SecurityUtilsExtension.encryptStringAsync2(fileName, account.decryptedDataKey!);
  }

  Future<Uint8List> _encryptAndCompressContent(List<int> content, ClientAccount account) async {
    final List<int> compressed = gzip.encode(content);
    // todo: maybe clear content list here, or also add a config option for the compression level
    return SecurityUtilsExtension.encryptBytesAsync(Uint8List.fromList(compressed), account.decryptedDataKey!);
  }
}

/// Use the fitting subclass for the use case!
abstract class StoreNoteEncryptedParams {
  /// If the note id is new, that means that the note is newly created
  final int noteId;

  /// An empty name means that the note was deleted! If this is [null] it means that the name did not change!
  final String? decryptedName;

  /// This can be empty if the file has no content yet and must be set if the note is newly created!
  /// If this is [null] it means that the file content did not change.
  final List<int>? decryptedContent;

  StoreNoteEncryptedParams({required this.noteId, required this.decryptedName, required this.decryptedContent});
}

class CreateNoteEncryptedParams extends StoreNoteEncryptedParams {
  /// This constructor is used when the note was newly created.
  /// The file name may not be empty!
  CreateNoteEncryptedParams({required int noteId, required String decryptedName, required Uint8List decryptedContent})
      : super(noteId: noteId, decryptedName: decryptedName, decryptedContent: decryptedContent) {
    if (decryptedName.isEmpty) {
      Logger.error("CreateNoteEncryptedParams: file name may not be empty");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
  }
}

class ChangeNoteEncryptedParams extends StoreNoteEncryptedParams {
  /// This constructor is used when the note was changed (renamed, or content changed).
  /// One of both must be not null and the file name may not be empty.
  ChangeNoteEncryptedParams({required super.noteId, required super.decryptedName, required super.decryptedContent}) {
    if (decryptedName == null && decryptedContent == null) {
      Logger.error("ChangeNoteEncryptedParams: One of the params must be non null");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    if (decryptedName?.isEmpty ?? false) {
      Logger.error("ChangeNoteEncryptedParams: file name may not be empty");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
  }
}

class DeleteNoteEncryptedParams extends StoreNoteEncryptedParams {
  /// This constructor is used when the note was deleted and the file name should be empty
  DeleteNoteEncryptedParams({required int noteId}) : super(noteId: noteId, decryptedName: "", decryptedContent: null);
}
