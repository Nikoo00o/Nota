import 'dart:io';
import 'dart:typed_data';

import 'package:app/core/config/app_config.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/remote_note_data_source.dart';
import 'package:app/domain/repositories/note_repository.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/dtos/notes/download_note_request.dart';
import 'package:shared/data/dtos/notes/download_note_response.dart';
import 'package:shared/data/dtos/notes/finish_note_request.dart';
import 'package:shared/data/dtos/notes/start_note_transfer_request.dart';
import 'package:shared/data/dtos/notes/start_note_transfer_response.dart';
import 'package:shared/data/dtos/notes/upload_note_request.dart';
import 'package:shared/data/models/note_info_model.dart';
import 'package:shared/data/models/note_update_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/note_update.dart';

/// For a description of the usage/workflow and the error codes, look at [RemoteNoteDataSource]
class NoteRepositoryImpl extends NoteRepository {
  final RemoteNoteDataSource remoteNoteDataSource;
  final LocalDataSource localDataSource;
  final AppConfig appConfig;

  /// Will be set in [startNoteTransfer] and cleared in [finishNoteTransfer]
  StartNoteTransferResponse? _currentCachedTransfer;

  NoteRepositoryImpl({required this.remoteNoteDataSource, required this.localDataSource, required this.appConfig});

  /// Stores the content of the note which is encrypted with the users data key.
  ///
  /// The Note will be stored at "[getApplicationDocumentsDirectory()] / [appConfig.noteFolder] / [noteId] .note"
  ///
  /// So for example on android /data/user/0/com.nota.nota_app/app_flutter/notes/10.note
  Future<void> storeEncryptedNote({required int noteId, required List<int> bytes, bool isTempNote = false}) async {
    await localDataSource.writeFile(localFilePath: getLocalNotePath(noteId: noteId, isTempNote: isTempNote), bytes: bytes);
  }

  /// Returns the content of the note which is encrypted with the users data key.
  ///
  /// The Note will be stored at "[getApplicationDocumentsDirectory()] / [appConfig.noteFolder] / [noteId] .note"
  ///
  /// So for example on android /data/user/0/com.nota.nota_app/app_flutter/notes/10.note
  ///
  /// If the note could not be found, this will throw a [FileException] with [ErrorCodes.FILE_NOT_FOUND]!
  Future<Uint8List> loadEncryptedNote({required int noteId, bool isTempNote = false}) async {
    final Uint8List? encryptedBytes =
        await localDataSource.readFile(localFilePath: getLocalNotePath(noteId: noteId, isTempNote: isTempNote));
    if (encryptedBytes == null) {
      throw const FileException(message: ErrorCodes.FILE_NOT_FOUND);
    }
    return encryptedBytes;
  }

  /// This starts the note transfer and can throw the exceptions of [RemoteNoteDataSource.startNoteTransferRequest].
  ///
  /// It also returns the note updates which the client has to deal with and store as temp changes until [finishNoteTransfer]
  Future<List<NoteUpdate>> startNoteTransfer(List<NoteInfo> clientNotes) async {
    Logger.debug("Starting note transfer");
    final List<NoteInfoModel> models = clientNotes.map((NoteInfo element) => NoteInfoModel.fromNoteInfo(element)).toList();

    final StartNoteTransferResponse response =
        await remoteNoteDataSource.startNoteTransferRequest(StartNoteTransferRequest(clientNotes: models));

    _currentCachedTransfer = response;
    return response.noteUpdates;
  }

  /// Either calls [RemoteNoteDataSource.downloadNoteRequest], or [RemoteNoteDataSource.uploadNoteRequest] depending on
  /// the [_currentCachedTransfer] and also throws the exceptions of those.
  ///
  /// It can also throw a [ClientException] with [ErrorCodes.CLIENT_NO_TRANSFER] if there is no active transfer, or if the
  /// [noteId] does not belong to the transfer!
  ///
  /// This either reads the data from a real note file, or saves the data in a new temp note file!
  Future<void> uploadOrDownloadNote({required int noteId}) async {
    _checkCachedTransfer(); // throws exception

    final Iterable<NoteUpdateModel> iterator = _currentCachedTransfer!.noteUpdates
        .where((NoteUpdateModel update) => update.clientId == noteId || update.serverId == noteId);
    if (iterator.length != 1) {
      Logger.error("Invalid note id $noteId for the transfer ${_currentCachedTransfer!.transferToken}");
      throw const ClientException(message: ErrorCodes.CLIENT_NO_TRANSFER);
    }

    if (iterator.first.noteTransferStatus.clientNeedsUpdate) {
      Logger.debug("Downloading note $noteId");
      final DownloadNoteResponse response = await remoteNoteDataSource
          .downloadNoteRequest(DownloadNoteRequest(transferToken: _currentCachedTransfer!.transferToken, noteId: noteId));

      await storeEncryptedNote(noteId: noteId, bytes: response.rawBytes);
    } else if (iterator.first.noteTransferStatus.serverNeedsUpdate) {
      Logger.debug("Uploading note $noteId");
      final Uint8List bytes = await loadEncryptedNote(noteId: noteId);

      await remoteNoteDataSource.uploadNoteRequest(
          UploadNoteRequest(transferToken: _currentCachedTransfer!.transferToken, noteId: noteId, rawBytes: bytes));
    } else {
      assert(false, "this should never happen during a note transfer!");
    }
  }

  /// Depending on [shouldCancel] this either cancels, or finishes the note transfer started with [startNoteTransfer].
  /// It can throw the exceptions of [RemoteNoteDataSource.finishNoteTransferRequest].
  /// And also a [ClientException] with [ErrorCodes.CLIENT_NO_TRANSFER] if there is no active transfer.
  ///
  /// This will apply the changes on the server side and now the client should also apply its temp changes afterwards.
  /// This also resets the cached transfer.
  Future<void> finishNoteTransfer({required bool shouldCancel}) async {
    _checkCachedTransfer(); // throws exception

    await remoteNoteDataSource.finishNoteTransferRequest(FinishNoteTransferRequestWithTransferToken(
        transferToken: _currentCachedTransfer!.transferToken, shouldCancel: shouldCancel));

    _currentCachedTransfer = null;
    Logger.debug("Finished note transfer");
  }

  void _checkCachedTransfer() {
    if (_currentCachedTransfer == null) {
      Logger.error("No cached transfer");
      throw const ClientException(message: ErrorCodes.CLIENT_NO_TRANSFER);
    }
  }

  /// Deletes all temp notes
  Future<void> clearTempNotes() async {
    final List<String> files = await _getAllNotes();
    files.removeWhere((String path) => path.endsWith(SharedConfig.noteFileEnding(isTempNote: true)) == false);
    Logger.debug("Clearing the temp notes: $files");
    for (final String path in files) {
      await localDataSource.deleteFile(localFilePath: path);
    }
  }

  /// Replaces the real notes with the temp notes that are currently stored if they are part of the note transfer!
  ///
  /// If this finds temp notes that are not part of the note transfer, those will get deleted!
  Future<void> replaceNotesWithTemp() async {
    final List<String> files = await _getAllNotes();
    files.removeWhere((String path) => path.endsWith(SharedConfig.noteFileEnding(isTempNote: true)) == false);
    Logger.debug("Clearing replacing the real notes with the following temp notes: $files");
    for (final String path in files) {
      await localDataSource.deleteFile(localFilePath: path);
    }
  }

  /// Renames a real note from the [oldNoteId] to the [newNoteId].
  ///
  /// If the [oldNoteId] file did not exist, it will throw a [FileException] with [ErrorCodes.FILE_NOT_FOUND]!
  Future<bool> renameNote({required int oldNoteId, required int newNoteId}) async {
    return localDataSource.renameFile(
      oldLocalFilePath: getLocalNotePath(noteId: oldNoteId, isTempNote: false),
      newLocalFilePath: getLocalNotePath(noteId: newNoteId, isTempNote: false),
    );
  }

  /// Returns if the file at [getApplicationDocumentsDirectory()] / [localFilePath] existed and if it was deleted, or not.
  ///
  /// The application documents directory will for example be: /data/user/0/com.nota.nota_app/app_flutter/
  Future<bool> deleteNote({required int noteId, bool isTempNote = false}) async {
    final String path = getLocalNotePath(noteId: noteId, isTempNote: isTempNote);
    Logger.debug("Deleting note $path");
    return localDataSource.deleteFile(localFilePath: path);
  }

  /// Returns a list of absolute note file paths
  Future<List<String>> _getAllNotes() async => localDataSource.getFilePaths(subFolderPath: appConfig.noteFolder);

  /// Returns the relative filePath to a specific note from the application documents directory.
  ///
  /// The Note will be stored at "[getApplicationDocumentsDirectory()] / [appConfig.noteFolder] / [noteId] .note"
  ///
  /// So for example on android /data/user/0/com.nota.nota_app/app_flutter/notes/10.note
  ///
  /// If [isTempNote] is true, then the note ending will be ".temp" instead.
  String getLocalNotePath({required int noteId, required bool isTempNote}) {
    final String ending = SharedConfig.noteFileEnding(isTempNote: isTempNote);
    return "${appConfig.noteFolder}${Platform.pathSeparator}$noteId$ending";
  }
}
