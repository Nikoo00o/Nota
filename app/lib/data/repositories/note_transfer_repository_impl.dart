import 'dart:io';
import 'dart:typed_data';

import 'package:app/core/config/app_config.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/remote_note_data_source.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
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
class NoteTransferRepositoryImpl extends NoteTransferRepository {
  final RemoteNoteDataSource remoteNoteDataSource;
  final LocalDataSource localDataSource;
  final AppConfig appConfig;

  /// Will be set in [startNoteTransfer] and cleared in [finishNoteTransfer]
  StartNoteTransferResponse? _currentCachedTransfer;

  NoteTransferRepositoryImpl({required this.remoteNoteDataSource, required this.localDataSource, required this.appConfig});

  @override
  Future<void> storeEncryptedNote({required int noteId, required List<int> encryptedBytes, bool isTempNote = false}) async {
    await localDataSource.writeFile(
        localFilePath: getLocalNotePath(noteId: noteId, isTempNote: isTempNote), bytes: encryptedBytes);
  }

  @override
  Future<Uint8List> loadEncryptedNote({required int noteId, bool isTempNote = false}) async {
    final Uint8List? encryptedBytes =
        await localDataSource.readFile(localFilePath: getLocalNotePath(noteId: noteId, isTempNote: isTempNote));
    if (encryptedBytes == null) {
      throw const FileException(message: ErrorCodes.FILE_NOT_FOUND);
    }
    return encryptedBytes;
  }

  @override
  Future<List<NoteUpdate>> startNoteTransfer(List<NoteInfo> clientNotes) async {
    Logger.debug("Starting note transfer");
    final List<NoteInfoModel> models = clientNotes.map((NoteInfo element) => NoteInfoModel.fromNoteInfo(element)).toList();

    final StartNoteTransferResponse response =
        await remoteNoteDataSource.startNoteTransferRequest(StartNoteTransferRequest(clientNotes: models));

    _currentCachedTransfer = response;
    return response.noteUpdates;
  }

  @override
  Future<void> uploadOrDownloadNote({required int noteClientId}) async {
    _checkCachedTransfer(); // throws exception

    final Iterable<NoteUpdateModel> iterator = _currentCachedTransfer!.noteUpdates
        .where((NoteUpdateModel update) => update.clientId == noteClientId || update.serverId == noteClientId);
    if (iterator.length != 1) {
      Logger.error("Invalid note id $noteClientId for the transfer ${_currentCachedTransfer!.transferToken}");
      throw const ClientException(message: ErrorCodes.CLIENT_NO_TRANSFER);
    }

    if (iterator.first.noteTransferStatus.clientNeedsUpdate) {
      Logger.debug("Downloading note $noteClientId");
      final DownloadNoteResponse response = await remoteNoteDataSource.downloadNoteRequest(DownloadNoteRequest(
        transferToken: _currentCachedTransfer!.transferToken,
        noteId: noteClientId,
      ));

      await storeEncryptedNote(noteId: noteClientId, encryptedBytes: response.rawBytes);
    } else if (iterator.first.noteTransferStatus.serverNeedsUpdate) {
      Logger.debug("Uploading note $noteClientId");
      final Uint8List bytes = await loadEncryptedNote(noteId: noteClientId);

      await remoteNoteDataSource.uploadNoteRequest(
          UploadNoteRequest(transferToken: _currentCachedTransfer!.transferToken, noteId: noteClientId, rawBytes: bytes));
    } else {
      Logger.error("The enum NoteTransferStatus is broken for ${iterator.first.noteTransferStatus}");
    }
    assert(
        iterator.first.noteTransferStatus.clientNeedsUpdate == false &&
            iterator.first.noteTransferStatus.serverNeedsUpdate == false,
        "this should never happen during a note transfer!");
  }

  @override
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

  @override
  Future<void> clearTempNotes() async {
    final List<String> files = await _getAllNotes();
    files.removeWhere((String path) => path.endsWith(SharedConfig.noteFileEnding(isTempNote: true)) == false);
    Logger.debug("Clearing the temp notes: $files");
    for (final String path in files) {
      await localDataSource.deleteFile(localFilePath: path);
    }
  }

  @override
  Future<void> replaceNotesWithTemp() async {
    final List<String> files = await _getAllNotes();
    files.removeWhere((String path) => path.endsWith(SharedConfig.noteFileEnding(isTempNote: true)) == false);
    Logger.debug("Clearing replacing the real notes with the following temp notes: $files");
    for (final String path in files) {
      await localDataSource.deleteFile(localFilePath: path);
    }
  }

  @override
  Future<bool> renameNote({required int oldNoteId, required int newNoteId}) async {
    return localDataSource.renameFile(
      oldLocalFilePath: getLocalNotePath(noteId: oldNoteId, isTempNote: false),
      newLocalFilePath: getLocalNotePath(noteId: newNoteId, isTempNote: false),
    );
  }

  @override
  Future<bool> deleteNote({required int noteId, bool isTempNote = false}) async {
    final String path = getLocalNotePath(noteId: noteId, isTempNote: isTempNote);
    Logger.debug("Deleting note $path");
    return localDataSource.deleteFile(localFilePath: path);
  }

  /// Returns a list of absolute note file paths
  Future<List<String>> _getAllNotes() async => localDataSource.getFilePaths(subFolderPath: appConfig.noteFolder);

  @override
  String getLocalNotePath({required int noteId, required bool isTempNote}) {
    final String ending = SharedConfig.noteFileEnding(isTempNote: isTempNote);
    return "${appConfig.noteFolder}${Platform.pathSeparator}$noteId$ending";
  }
}
