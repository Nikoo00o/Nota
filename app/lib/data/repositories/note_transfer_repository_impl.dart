import 'dart:io';
import 'dart:typed_data';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/remote_note_data_source.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_transfer_status.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/data/dtos/notes/download_note_request.dart';
import 'package:shared/data/dtos/notes/download_note_response.dart';
import 'package:shared/data/dtos/notes/finish_note_request.dart';
import 'package:shared/data/dtos/notes/should_upload_note_request.dart';
import 'package:shared/data/dtos/notes/should_upload_note_response.dart';
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

  NoteTransferRepositoryImpl(
      {required this.remoteNoteDataSource, required this.localDataSource, required this.appConfig});

  @override
  Future<void> storeEncryptedNote({required int noteId, required List<int> encryptedBytes}) async =>
      _storeEncryptedNoteInternal(noteId: noteId, encryptedBytes: encryptedBytes, isTempNote: false);

  Future<void> _storeEncryptedNoteInternal(
          {required int noteId, required List<int> encryptedBytes, required bool isTempNote}) async =>
      localDataSource.writeFile(
          localFilePath: getLocalNotePath(noteId: noteId, isTempNote: isTempNote), bytes: encryptedBytes);

  @override
  Future<Uint8List> loadEncryptedNote({required int noteId}) async {
    final Uint8List? encryptedBytes =
        await localDataSource.readFile(localFilePath: getLocalNotePath(noteId: noteId, isTempNote: false));
    if (encryptedBytes == null) {
      throw FileException(message: ErrorCodes.FILE_NOT_FOUND, messageParams: <String>[noteId.toString()]);
    }
    return encryptedBytes;
  }

  @override
  Future<List<NoteUpdate>> startNoteTransfer(List<NoteInfo> clientNotes) async {
    Logger.debug("Starting note transfer");
    final List<NoteInfoModel> models =
        clientNotes.map((NoteInfo element) => NoteInfoModel.fromNoteInfo(element)).toList();

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
    final NoteTransferStatus noteTransferStatus = iterator.first.noteTransferStatus;

    if (noteTransferStatus.clientNeedsUpdate) {
      Logger.debug("Downloading note $noteClientId");
      List<int>? hashBytes;
      if (noteTransferStatus.wasNewSaved == false) {
        final Uint8List? bytes =
            await localDataSource.readFile(localFilePath: getLocalNotePath(noteId: noteClientId, isTempNote: false));
        // this can be null if local note was deleted, but server has newer version
        if (bytes != null) {
          hashBytes = await SecurityUtilsExtension.hashBytesAsync(bytes);
        }
      }
      final DownloadNoteResponse response = await remoteNoteDataSource.downloadNoteRequest(DownloadNoteRequest(
        transferToken: _currentCachedTransfer!.transferToken,
        noteId: noteClientId,
        hashBytes: hashBytes,
      ));
      if (response.rawBytes.isNotEmpty) {
        await _storeEncryptedNoteInternal(noteId: noteClientId, encryptedBytes: response.rawBytes, isTempNote: true);
      } else {
        Logger.verbose("skipped content download, because the hashes were equal");
      }
    } else if (noteTransferStatus.serverNeedsUpdate) {
      Logger.debug("Uploading note $noteClientId");
      final Uint8List bytes = await loadEncryptedNote(noteId: noteClientId);
      bool shouldUpload = true;
      if (noteTransferStatus.wasNewSaved == false) {
        final ShouldUploadNoteResponse response =
            await remoteNoteDataSource.shouldUploadNoteRequest(ShouldUploadNoteRequest(
          transferToken: _currentCachedTransfer!.transferToken,
          noteId: noteClientId,
          hashBytes: await SecurityUtilsExtension.hashBytesAsync(bytes),
        ));
        shouldUpload = response.shouldUpload;
      }
      if (shouldUpload) {
        await remoteNoteDataSource.uploadNoteRequest(UploadNoteRequest(
          transferToken: _currentCachedTransfer!.transferToken,
          noteId: noteClientId,
          rawBytes: bytes,
        ));
      } else {
        Logger.verbose("skipped content upload, because the hashes were equal");
      }
    } else {
      Logger.error("The enum NoteTransferStatus is broken for $noteTransferStatus");
    }

    assert(noteTransferStatus.clientNeedsUpdate || noteTransferStatus.serverNeedsUpdate,
        "both client needs update and server needs update should never be false!");
  }

  @override
  Future<void> finishNoteTransfer({required bool shouldCancel}) async {
    _checkCachedTransfer(); // throws exception

    await remoteNoteDataSource.finishNoteTransferRequest(FinishNoteTransferRequestWithTransferToken(
        transferToken: _currentCachedTransfer!.transferToken, shouldCancel: shouldCancel));

    _currentCachedTransfer = null;
    await localDataSource.setLastNoteTransferTime(timeStamp: DateTime.now());
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
    final String tempEnding = SharedConfig.noteFileEnding(isTempNote: true);
    files.removeWhere((String path) => path.endsWith(SharedConfig.noteFileEnding(isTempNote: true)) == false);
    final RegExp endingMatch = RegExp("\\$tempEnding\$"); //the regex escapes the dot (.) of the file ending

    Logger.debug("Replacing the real notes with the following temp notes: $files");
    for (final String path in files) {
      final String newPath = path.replaceFirst(endingMatch, SharedConfig.noteFileEnding(isTempNote: false));
      await localDataSource.renameFile(oldLocalFilePath: path, newLocalFilePath: newPath);
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
  Future<bool> deleteNote({required int noteId}) async {
    final String path = getLocalNotePath(noteId: noteId, isTempNote: false);
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
