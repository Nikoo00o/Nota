import 'dart:typed_data';
import 'package:app/core/config/app_config.dart';
import 'package:app/data/datasources/remote_note_data_source.dart';
import 'package:app/domain/usecases/note_transfer/load_note_buffer.dart';
import 'package:app/domain/usecases/note_transfer/save_note_buffer.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/note_update.dart';

/// For a description of the usage/workflow and the error codes, look at [RemoteNoteDataSource]
abstract class NoteTransferRepository {
  /// Stores the content of the note which is encrypted with the users data key.
  ///
  /// The Note will be stored at "[getApplicationDocumentsDirectory()] / [AppConfig.noteFolder] / [noteId] .note"
  ///
  /// So for example on android /data/user/0/com.nota.nota_app/app_flutter/notes/10.note
  Future<void> storeEncryptedNote({required int noteId, required List<int> encryptedBytes});

  /// Returns the content of the note which is encrypted with the users data key.
  ///
  /// The Note will be stored at "[getApplicationDocumentsDirectory()] / [AppConfig.noteFolder] / [noteId] .note"
  ///
  /// So for example on android /data/user/0/com.nota.nota_app/app_flutter/notes/10.note
  ///
  /// If the note could not be found, this will throw a [FileException] with [ErrorCodes.FILE_NOT_FOUND]!
  Future<Uint8List> loadEncryptedNote({required int noteId});

  /// This starts the note transfer and can throw the exceptions of [RemoteNoteDataSource.startNoteTransferRequest].
  ///
  /// It also returns the note updates which the client has to deal with and store as temp changes until [finishNoteTransfer]
  Future<List<NoteUpdate>> startNoteTransfer(List<NoteInfo> clientNotes);

  /// Either calls [RemoteNoteDataSource.downloadNoteRequest], or [RemoteNoteDataSource.uploadNoteRequest] depending on
  /// the [_currentCachedTransfer] and also throws the exceptions of those.
  ///
  /// It can also throw a [ClientException] with [ErrorCodes.CLIENT_NO_TRANSFER] if there is no active transfer, or if the
  /// [noteClientId] does not belong to the transfer!
  ///
  /// This either reads the data from a real note file, or saves the data in a new temp note file!
  ///
  /// [noteClientId] should always be the real client id!!
  Future<void> uploadOrDownloadNote({required int noteClientId});

  /// Depending on [shouldCancel] this either cancels, or finishes the note transfer started with [startNoteTransfer].
  /// It can throw the exceptions of [RemoteNoteDataSource.finishNoteTransferRequest].
  /// And also a [ClientException] with [ErrorCodes.CLIENT_NO_TRANSFER] if there is no active transfer.
  ///
  /// This will apply the changes on the server side and now the client should also apply its temp changes afterwards.
  /// This also resets the cached transfer.
  Future<void> finishNoteTransfer({required bool shouldCancel});

  /// Deletes all temp notes
  Future<void> clearTempNotes();

  /// Replaces the real notes with the temp notes that are currently stored if they are part of the note transfer!
  ///
  /// If this finds temp notes that are not part of the note transfer, those will get deleted!
  Future<void> replaceNotesWithTemp();

  /// Renames a real note from the [oldNoteId] to the [newNoteId].
  ///
  /// If the [oldNoteId] file did not exist, it will throw a [FileException] with [ErrorCodes.FILE_NOT_FOUND]!
  Future<bool> renameNote({required int oldNoteId, required int newNoteId});

  /// Returns if the file at [getApplicationDocumentsDirectory()] / [getLocalNotePath] existed and if it was deleted, or not.
  ///
  /// The application documents directory will for example be: /data/user/0/com.nota.nota_app/app_flutter/
  Future<bool> deleteNote({required int noteId});

  /// Returns the relative filePath to a specific note from the application documents directory.
  ///
  /// The Note will be stored at "[getApplicationDocumentsDirectory()] / [AppConfig.noteFolder] / [noteId] .note"
  ///
  /// So for example on android /data/user/0/com.nota.nota_app/app_flutter/notes/10.note
  ///
  /// If [isTempNote] is true, then the note ending will be ".temp" instead.
  String getLocalNotePath({required int noteId, required bool isTempNote});

  /// This is used directly inside of [LoadNoteBuffer] and [SaveNoteBuffer] to cache encrypted note content!
  Uint8List? encryptedNoteBufferCache;
}
