import 'dart:io';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/data/datasources/note_data_source.dart';
import 'package:server/data/models/server_account_model.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/core/network/rest_callback.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/core/enums/note_transfer_status.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/dtos/account/account_change_password_request.dart';
import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';
import 'package:shared/data/dtos/notes/start_note_transfer_request.dart';
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

  NoteRepository({required this.noteDataSource, required this.serverConfig});

  Future<RestCallbackResult> handleStartNoteTransfer(RestCallbackParams params) async {
    final ServerAccount serverAccount = params.getAttachedServerAccount();
    final StartNoteTransferRequest request = StartNoteTransferRequest.fromJson(params.jsonBody!);
    if (request.clientNotes.isEmpty) {
      Logger.error("Error Starting note transfer, because the request is empty: ${serverAccount.userName}");
      return RestCallbackResult.withErrorCode(ErrorCodes.SERVER_EMPTY_REQUEST_VALUES);
    }
    // first create the note transaction and compare file timestamps.
    // then send a list of needed updates

    // maybe already set server ids (with client ids saved as well) for the notes that should be newly created IN THE
    // TRANSACTION ONLY!

    // also already set the name changes in the transactions!

    throw UnimplementedError();
  }

  Future<RestCallbackResult> handleDownloadNote(RestCallbackParams params) async {
    // then download, or upload the files and store them in a new temp db for the transaction

    throw UnimplementedError();
  }

  Future<RestCallbackResult> handleUploadNote(RestCallbackParams params) async {
    // then download, or upload the files and store them in a new temp db for the transaction
    final String transactionToken = _getTransactionToken(params);
    // transaction token will be in query string and this will not have a dto

    // also needs the note id in the query string (can be client only)

    throw UnimplementedError();
  }

  Future<RestCallbackResult> handleFinishNoteTransfer(RestCallbackParams params) async {
    // finally finish transaction, load the stuff from file, save it in the real db, cancel other transactions

    // also delete the notes which now have the deleted bool set to true (of course client side should do the same, or can
    // already do that in the start)

    // will also only contain the transaction token in query params and not have any dto

    throw UnimplementedError();
  }

  /// The returned list elements will be of type [NoteUpdateModel], so they can also be used in repositories for
  /// communication.
  ///
  /// Also already adds the correct server id for new notes in the update list!
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

    return noteUpdates;
  }

  Future<void> _addNoteUpdate(List<NoteUpdate> noteUpdates, NoteInfo note, NoteTransferStatus noteTransferStatus) async {
    int serverId = note.id;
    if (noteTransferStatus == NoteTransferStatus.SERVER_NEEDS_NEW) {
      serverId = await noteDataSource.getNewNoteCounter();
    }
    noteUpdates.add(NoteUpdateModel(
      clientId: note.id,
      serverId: serverId,
      newEncFileName: note.encFileName,
      newLastEdited: note.lastEdited,
      noteTransferStatus: noteTransferStatus,
    ));
  }

  void _addComparedNoteUpdate(List<NoteUpdate> noteUpdates, {required NoteInfo clientNote, required NoteInfo serverNote}) {
    // ids are the same
    if (clientNote.lastEdited.isBefore(serverNote.lastEdited)) {
      noteUpdates.add(NoteUpdateModel(
        clientId: clientNote.id,
        serverId: serverNote.id,
        newEncFileName: clientNote.encFileName != serverNote.encFileName ? serverNote.encFileName : null,
        newLastEdited: serverNote.lastEdited,
        noteTransferStatus: NoteTransferStatus.CLIENT_NEEDS_UPDATE,
      ));
    } else if (serverNote.lastEdited.isBefore(clientNote.lastEdited)) {
      noteUpdates.add(NoteUpdateModel(
        clientId: clientNote.id,
        serverId: serverNote.id,
        newEncFileName: clientNote.encFileName != serverNote.encFileName ? clientNote.encFileName : null,
        newLastEdited: clientNote.lastEdited,
        noteTransferStatus: NoteTransferStatus.SERVER_NEEDS_UPDATE,
      ));
    }
    // the notes had the same time stamp, so they are the same, because its practically impossible to
  }

  String _getTransactionToken(RestCallbackParams params) => params.queryParams[RestJsonParameter.TRANSFER_TOKEN] ?? "";
}
