import 'dart:io';
import 'dart:typed_data';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/data/datasources/note_data_source.dart';
import 'package:server/data/models/server_account_model.dart';
import 'package:server/data/repositories/account_repository.dart';
import 'package:server/domain/entities/network/rest_callback_params.dart';
import 'package:server/domain/entities/network/rest_callback_result.dart';
import 'package:server/domain/entities/note_transfer.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/domain/entities/network/rest_callback.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/enums/note_transfer_status.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/string_utils.dart';
import 'package:shared/data/dtos/account/account_change_password_request.dart';
import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';
import 'package:shared/data/dtos/notes/finish_note_request.dart';
import 'package:shared/data/dtos/notes/start_note_transfer_request.dart';
import 'package:shared/data/dtos/notes/start_note_transfer_response.dart';
import 'package:shared/data/models/note_info_model.dart';
import 'package:shared/data/models/note_update_model.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/note_update.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/entities/shared_account.dart';
import 'package:synchronized/synchronized.dart';

/// Manages and synchronizes the note operations on the server by using the [NoteDataSource].
///
/// No Other Repository, or DataSource should access the notes from the [NoteDataSource] directly!!!
class NoteRepository {
  final NoteDataSource noteDataSource;
  final ServerConfig serverConfig;
  final AccountRepository accountRepository;

  /// Stores the note transfers with the transfer token as key and the note update list as value
  final Map<String, NoteTransfer> _noteTransfers = <String, NoteTransfer>{};

  /// Used to synchronize start and finish of the note transfer, because the finish cancels all started note transfers and
  /// might modify the accounts note data.
  /// Otherwise it could happen that a transfer starts and still has the old noteInfoList of the server account, then the
  /// last finish call updates the noteInfoList and cancels all other transfers and only then will the start add its own new
  /// transfer. So then the newly started transfer would have the wrong noteInfoList
  final Lock _startFinishLock = Lock();

  NoteRepository({required this.noteDataSource, required this.serverConfig, required this.accountRepository});

  /// Starts a note transfer and sends a response with the information to the client which notes to delete, rename, or
  /// swap client ids for server ids!
  /// Important: these changes should be cached and only be applied at the end after [handleFinishNoteTransfer], because
  /// otherwise the client could have changes (like server ids, or renames) that the server threw away again, because the
  /// transfer got cancelled!
  ///
  /// Afterwards the client should call [handleDownloadNote] and [handleUploadNote] for each affected note that is not empty
  /// depending on the status of the response of this request.
  ///
  /// At the end to apply the transfer on the server side, the client should call [handleFinishNoteTransfer], but it can
  /// also be called earlier to cancel the transfer.
  ///
  /// This request can return [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the  client sends a server note id that
  /// doesn't belong to it!
  Future<RestCallbackResult> handleStartNoteTransfer(RestCallbackParams params) async {
    return _startFinishLock.synchronized(() async {
      final ServerAccount serverAccount = params.getAttachedServerAccount(); // security: check authenticated account
      final StartNoteTransferRequest request = StartNoteTransferRequest.fromJson(params.jsonBody!);

      late final List<NoteUpdate> noteUpdates;
      try {
        noteUpdates = await compareClientAndServerNotes(request.clientNotes, serverAccount.noteInfoList); // security: check
        // if note ids from the client really belong to the account
      } on BaseException catch (e) {
        Logger.error("Error starting note transfer because of invalid note ids for: ${serverAccount.userName}");
        return RestCallbackResult.withErrorCode(e.message ?? ""); // [ErrorCodes.SERVER_INVALID_REQUEST_VALUES]
      }

      final StartNoteTransferResponse response = StartNoteTransferResponse(
        transferToken: _createNewTransferToken(),
        noteUpdates: List<NoteUpdateModel>.from(noteUpdates),
      );

      _noteTransfers[response.transferToken] = NoteTransfer(serverAccount: serverAccount, noteUpdates: response.noteUpdates);

      Logger.info("Created the new note transfer ${response.transferToken} for "
          "${serverAccount.userName} with ${response.noteUpdates}");
      // the client can now update name and ids and delete notes and then send/receive data. or it can cancel the transfer.
      return RestCallbackResult.withResponse(response);
    });
  }

  /// This request works with raw bytes as output and it needs the following query params:
  /// [RestJsonParameter.TRANSFER_TOKEN] from the call to [handleStartNoteTransfer]
  /// [RestJsonParameter.TRANSFER_NOTE_ID] for the affected note which should be downloaded from the server
  ///
  /// This request can return the error code [ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN] if the
  /// client used an invalid transfer token, or if the server cancelled the note transfer!
  /// It can also return the error code [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the client sends a server note id
  /// that doesn't belong to it!
  /// And [ErrorCodes.FILE_NOT_FOUND] is returned if the server could not find the note file.
  Future<RestCallbackResult> handleDownloadNote(RestCallbackParams params) async {
    final ServerAccount serverAccount = params.getAttachedServerAccount(); // security: check authenticated account
    final String transferToken = _getValidTransferToken(params, serverAccount);

    if (transferToken.isEmpty) {
      // security: check if the transfer token belongs to a transaction of this account
      Logger.error("Error downloading note, because the transfer token was invalid from ${serverAccount.userName}");
      return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN);
    }

    final int serverNoteId = _getValidServerNoteId(params, _noteTransfers[transferToken]!); // security: check if the note
    // belongs to the transaction and to the account. Also map a client id to a server id!
    if (serverNoteId == 0) {
      Logger.error("Error downloading note, because the note id was invalid: $transferToken");
      return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_INVALID_REQUEST_VALUES);
    }

    late final Uint8List bytes;
    try {
      bytes = await noteDataSource.loadNoteData(serverNoteId);
    } on BaseException catch (e) {
      Logger.error("Error downloading note for $transferToken");
      return RestCallbackResult.withErrorCode(e.message ?? "");
    }

    Logger.info("Downloaded file data for file $serverNoteId for the transfer $transferToken ");
    return RestCallbackResult(rawBytes: bytes);
  }

  /// This request works with raw bytes as input and it needs the following query params:
  /// [RestJsonParameter.TRANSFER_TOKEN] from the call to [handleStartNoteTransfer]
  /// [RestJsonParameter.TRANSFER_NOTE_ID] for the affected note which should be uploaded to the server
  ///
  /// This request can return [ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN] if the  client used an invalid transfer
  /// token, or if the server cancelled the note transfer!
  /// It can also return [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the client sends a server note id  that doesn't
  /// belong to it!
  Future<RestCallbackResult> handleUploadNote(RestCallbackParams params) async {
    final ServerAccount serverAccount = params.getAttachedServerAccount();
    final String transferToken = _getValidTransferToken(params, serverAccount);

    if (transferToken.isEmpty) {
      Logger.error("Error uploading note, because the transfer token was invalid from ${serverAccount.userName}");
      return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN);
    }
    if (params.rawBytes?.isEmpty ?? true) {
      Logger.error("Error uploading note, because the request is empty: $transferToken");
      return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_INVALID_REQUEST_VALUES);
    }

    final int serverNoteId = _getValidServerNoteId(params, _noteTransfers[transferToken]!);
    if (serverNoteId == 0) {
      Logger.error("Error uploading note, because the note id was invalid: $transferToken");
      return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_INVALID_REQUEST_VALUES);
    }

    await noteDataSource.saveTempNoteData(serverNoteId, transferToken, params.rawBytes!);

    Logger.info("Uploaded file data for file $serverNoteId for the transfer $transferToken ");
    return RestCallbackResult();
  }

  /// Finishes a note transfer that was started with the note transfer token from [handleStartNoteTransfer] and cancels all
  /// other transfers for this [ServerAccount].
  ///
  /// Otherwise if [FinishNoteTransferRequest.shouldCancel] is [true], then only this specific note transfer with the
  /// transfer token will be cancelled!
  ///
  /// This request can return [ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN] if the client used an invalid transfer
  /// token, or if the server cancelled the note transfer!
  ///
  /// It can also return [ErrorCodes.FILE_NOT_FOUND] if something fails during the transfer finish.
  ///
  /// Now the client can also apply its temporary cached changes from the [handleStartNoteTransfer] response!
  Future<RestCallbackResult> handleFinishNoteTransfer(RestCallbackParams params) async {
    return _startFinishLock.synchronized(() async {
      final ServerAccount serverAccount = params.getAttachedServerAccount();
      final String transferToken = _getValidTransferToken(params, serverAccount);

      if (transferToken.isEmpty) {
        Logger.error("Error finishing note transfer, because the transfer token was invalid from ${serverAccount.userName}");
        return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN);
      }

      final FinishNoteTransferRequest request = FinishNoteTransferRequest.fromJson(params.jsonBody!);

      try {
        if (request.shouldCancel) {
          await _cancelTransfer(transferToken);
        } else {
          Logger.debug("Applying note file transfer to old account data $serverAccount");
          await _applyTransfer(transferToken);
          await _cancelAllTransfers(serverAccount);
          await accountRepository.storeAccount(serverAccount);
          Logger.debug("Finished note file transfer with new account data $serverAccount");
        }
      } on BaseException catch (e) {
        Logger.error("Error finishing note transfer for $transferToken");
        return RestCallbackResult.withErrorCode(e.message ?? "");
      }

      final String logAction = request.shouldCancel ? "cancelled" : "completed";
      Logger.info("Note file transfer $transferToken was $logAction from account ${serverAccount.userName}");
      return RestCallbackResult();
    });
  }

  /// Cleans up old transfers for accounts that do not have a valid session token (so they are not logged in anymore)
  Future<void> cleanUpOldTransfers() async {
    final List<String> transfersToCancel = List<String>.empty(growable: true);
    for (final iterator in _noteTransfers.entries) {
      final String transferToken = iterator.key;
      final NoteTransfer noteTransfer = iterator.value;
      if (noteTransfer.serverAccount.isSessionTokenStillValid() == false) {
        Logger.debug("Cancelling old note transfer $noteTransfer");
        transfersToCancel.add(transferToken);
      }
    }
    for (final String transferToken in transfersToCancel) {
      await _cancelTransfer(transferToken);
    }
  }

  Future<void> _cancelTransfer(String transferToken) async {
    if (_noteTransfers.containsKey(transferToken)) {
      Logger.debug("Cancelling transfer: $transferToken");
      _noteTransfers.remove(transferToken);
      await noteDataSource.deleteAllTempNotes(transferToken: transferToken);
    } else {
      Logger.warn("Could not cancel transfer: $transferToken");
    }
  }

  /// Cancels every transfer for the [account]
  Future<void> _cancelAllTransfers(ServerAccount account) async {
    Logger.debug("Cancelling all transfers for ${account.userName}");
    final List<String> transfersToCancel = List<String>.empty(growable: true);
    for (final iterator in _noteTransfers.entries) {
      final String transferToken = iterator.key;
      final NoteTransfer noteTransfer = iterator.value;
      if (noteTransfer.serverAccount == account) {
        transfersToCancel.add(transferToken);
      }
    }
    for (final String transferToken in transfersToCancel) {
      await _cancelTransfer(transferToken);
    }
  }

  /// Does not remove any note transfers (but the tmp note files will of course be removed, because they are renamed)
  /// Can throw a [FileException] with [ErrorCodes.FILE_NOT_FOUND]
  Future<void> _applyTransfer(String transferToken) async {
    if (_noteTransfers.containsKey(transferToken)) {
      final NoteTransfer noteTransfer = _noteTransfers[transferToken]!;
      for (final NoteUpdate noteUpdate in noteTransfer.noteUpdates) {
        if (noteUpdate.noteTransferStatus.serverNeedsUpdate) {
          Logger.debug("Applying $noteUpdate");
          await _updateAccountNoteList(noteUpdate, noteTransfer.serverAccount); // update account data
          await _updateStoredNotes(noteUpdate, transferToken); // update note data
        }
      }
    } else {
      Logger.warn("Could not apply transfer: $transferToken");
    }
  }

  /// Modifies the list of notes from the account according to the note update by updating file name, time stamp and
  /// adding new entries.
  /// The noteUpdates transfer status must be one of serverNeedsUpdate.
  Future<void> _updateAccountNoteList(NoteUpdate noteUpdate, ServerAccount serverAccount) async {
    assert(noteUpdate.noteTransferStatus.serverNeedsUpdate, "note transfer status must be one of serverNeedsUpdate");
    for (int i = 0; i < serverAccount.noteInfoList.length; ++i) {
      final NoteInfoModel noteInfo = NoteInfoModel.fromNoteInfo(serverAccount.noteInfoList[i]);
      if (noteInfo.id == noteUpdate.serverId) {
        serverAccount.noteInfoList[i] = noteInfo.copyWith(
          newEncFileName: noteUpdate.newEncFileName,
          newLastEdited: noteUpdate.newLastEdited,
        );
        return; // update the element
      }
    }
    // not found, so add a new one
    serverAccount.noteInfoList.add(NoteInfoModel(
      id: noteUpdate.serverId,
      encFileName: noteUpdate.newEncFileName ?? "",
      lastEdited: noteUpdate.newLastEdited,
    ));
  }

  /// Depending on the note update, either deletes the note data, or replaces it with the temp note data, or do nothing
  /// The noteUpdates transfer status must be one of serverNeedsUpdate.
  /// Can throw a [FileException] with [ErrorCodes.FILE_NOT_FOUND]
  Future<void> _updateStoredNotes(NoteUpdate noteUpdate, String transferToken) async {
    assert(noteUpdate.noteTransferStatus.serverNeedsUpdate, "note transfer status must be one of serverNeedsUpdate");
    try {
      if (noteUpdate.wasFileDeleted) {
        await noteDataSource.deleteNoteData(noteUpdate.serverId); // delete file if filename was empty
      } else {
        await noteDataSource.replaceNoteDataWithTempData(noteUpdate.serverId, transferToken); // update file if data
        // was send
      }
    } catch (_) {
      Logger.warn("Client did not send any note file data");
    }
  }

  /// The returned list elements will be of type [NoteUpdateModel], so they can also be used in repositories for
  /// communication.
  ///
  /// This also already adds the correct server id for new notes in the update list and sets the correct new file name!
  ///
  /// If [clientNotes] contains a server id (>0) that does not exist in [serverNotes], then a [ServerException] with
  /// [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] will be thrown, because then the notes do not belong to the account!
  Future<List<NoteUpdate>> compareClientAndServerNotes(List<NoteInfo> clientNotes, List<NoteInfo> serverNotes) async {
    final List<NoteUpdate> noteUpdates = List<NoteUpdate>.empty(growable: true);
    final List<NoteInfo> sortedClientNotes = List<NoteInfo>.from(clientNotes);
    final List<NoteInfo> sortedServerNotes = List<NoteInfo>.from(serverNotes);
    sortedClientNotes.sort(NoteInfo.compareById);
    sortedServerNotes.sort(NoteInfo.compareById);

    for (int c = 0, s = 0; c < sortedClientNotes.length || s < sortedServerNotes.length;) {
      NoteInfo? clientNote;
      NoteInfo? serverNote;
      if (c < sortedClientNotes.length) {
        clientNote = sortedClientNotes[c];
      }
      if (s < sortedServerNotes.length) {
        serverNote = sortedServerNotes[s];
      }

      if (clientNote != null && serverNote != null) {
        if (clientNote.id < serverNote.id) {
          c++; // add new note from client, because the server did not have it yet and increment the client counter
          await _addNoteUpdate(noteUpdates, clientNote, NoteTransferStatus.SERVER_NEEDS_NEW);
        } else if (clientNote.id > serverNote.id) {
          s++; // add new note from server, because the client did not have it yet and increment the server counter
          await _addNoteUpdate(noteUpdates, serverNote, NoteTransferStatus.CLIENT_NEEDS_NEW);
        } else {
          _addComparedNoteUpdate(noteUpdates, clientNote: clientNote, serverNote: serverNote);
          c++; // ids are equal, so compare time stamps and increment both counters
          s++;
        }
      } else if (clientNote == null && serverNote != null) {
        s++; // no more client notes are available, so add remaining server notes
        await _addNoteUpdate(noteUpdates, serverNote, NoteTransferStatus.CLIENT_NEEDS_NEW);
      } else if (serverNote == null && clientNote != null) {
        c++; // no more server notes are available, so add remaining client notes
        await _addNoteUpdate(noteUpdates, clientNote, NoteTransferStatus.SERVER_NEEDS_NEW);
      }
    }

    return noteUpdates..sort(NoteUpdate.compareByServerId);
  }

  Future<void> _addNoteUpdate(List<NoteUpdate> noteUpdates, NoteInfo note, NoteTransferStatus noteTransferStatus) async {
    int serverId = note.id;
    if (noteTransferStatus == NoteTransferStatus.SERVER_NEEDS_NEW) {
      if (note.id >= 0) {
        throw const ServerException(message: ErrorCodes.SERVER_INVALID_REQUEST_VALUES);
      }
      serverId = await noteDataSource.getNewNoteCounter();
    }
    noteUpdates.add(_createNoteUpdate(
      newNote: note,
      noteTransferStatus: noteTransferStatus,
      newServerId: serverId,
    ));
  }

  void _addComparedNoteUpdate(List<NoteUpdate> noteUpdates, {required NoteInfo clientNote, required NoteInfo serverNote}) {
    assert(clientNote.id == serverNote.id, "both ids are the same server id");

    if (clientNote.lastEdited.isBefore(serverNote.lastEdited)) {
      noteUpdates.add(_createNoteUpdate(
        newNote: serverNote,
        oldEncFileName: clientNote.encFileName,
        noteTransferStatus: NoteTransferStatus.CLIENT_NEEDS_UPDATE,
      ));
    } else if (serverNote.lastEdited.isBefore(clientNote.lastEdited)) {
      noteUpdates.add(_createNoteUpdate(
        newNote: clientNote,
        oldEncFileName: serverNote.encFileName,
        noteTransferStatus: NoteTransferStatus.SERVER_NEEDS_UPDATE,
      ));
    }
    // the notes had the same time stamp, so they are the same, because its practically impossible to
  }

  /// Creates a [NoteUpdateModel] from [newNote] with the note transfer status [noteTransferStatus].
  ///
  /// If [newServerId] is not null, then it will override the server id of the model
  ///
  /// If the encrypted file name of the new note is not equal to [oldEncFileName], then it will be used. Otherwise null
  /// will be used (same as if [oldEncFileName] is null).
  /// If the [oldEncFileName] is null, then that means that the new and old note had the same encrypted file name.
  NoteUpdateModel _createNoteUpdate({
    required NoteInfo newNote,
    required NoteTransferStatus noteTransferStatus,
    String? oldEncFileName,
    int? newServerId,
  }) {
    return NoteUpdateModel(
      clientId: newNote.id,
      serverId: newServerId ?? newNote.id,
      newEncFileName: newNote.encFileName != oldEncFileName ? newNote.encFileName : null,
      newLastEdited: newNote.lastEdited,
      noteTransferStatus: noteTransferStatus,
    );
  }

  String _createNewTransferToken() {
    late String transferToken;
    do {
      transferToken = StringUtils.getRandomBytesAsBase64String(SharedConfig.keyBytes);
    } while (_noteTransfers.containsKey(transferToken));
    return transferToken;
  }

  /// Returns the transfer token from the query parameters if it is contained in the note transfers and if the attached
  /// account matches!
  ///
  /// Otherwise the returned transfer token will be empty
  String _getValidTransferToken(RestCallbackParams params, ServerAccount serverAccount) {
    final String? transferToken = params.queryParams[RestJsonParameter.TRANSFER_TOKEN];
    if (transferToken == null ||
        transferToken.isEmpty ||
        _noteTransfers.containsKey(transferToken) == false ||
        _noteTransfers[transferToken]!.serverAccount != serverAccount) {
      Logger.warn("Got an invalid transfer token $transferToken from ${serverAccount.userName}");
      return "";
    }
    return transferToken;
  }

  /// Returns the server note id from the params if the note id is a valid server, or client id that is contained in the
  /// matching transfer. Otherwise 0 will be returned if a server, or client id was used that does not belong to the transfer!
  ///
  /// This will always return the matching mapped server id and never return the client id!
  int _getValidServerNoteId(RestCallbackParams params, NoteTransfer noteTransfer) {
    final String idString = params.queryParams[RestJsonParameter.TRANSFER_NOTE_ID] ?? "0";
    final int id = int.tryParse(idString) ?? 0;
    final Iterable<NoteUpdate> iterator =
        noteTransfer.noteUpdates.where((NoteUpdate noteUpdate) => noteUpdate.serverId == id || noteUpdate.clientId == id);
    if (iterator.isEmpty) {
      Logger.warn("Got an invalid id $id from ${noteTransfer.serverAccount.userName}");
      return 0;
    } else if (iterator.first.noteTransferStatus.clientNeedsUpdate && (params.rawBytes?.isNotEmpty ?? false)) {
      Logger.warn("The client uploaded bytes to override a note for which the server had a newer time stamp in the "
          "transfer");
    }
    assert(iterator.length == 1, "There should always only be one matching note update for each file!");
    return iterator.first.serverId;
  }

  /// Returns the note transfers unmodifiable for read only access. The note transfers themselves should not be modified!
  Map<String, NoteTransfer> getReadOnlyNoteTransfers() => Map<String, NoteTransfer>.unmodifiable(_noteTransfers);
}
