import 'package:app/domain/usecases/account/fetch_current_session_token.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/data/dtos/notes/download_note_request.dart';
import 'package:shared/data/dtos/notes/download_note_response.dart';
import 'package:shared/data/dtos/notes/finish_note_request.dart';
import 'package:shared/data/dtos/notes/start_note_transfer_request.dart';
import 'package:shared/data/dtos/notes/start_note_transfer_response.dart';
import 'package:shared/data/dtos/notes/upload_note_request.dart';
import 'package:shared/domain/entities/note_update.dart';
import 'package:shared/domain/entities/response_data.dart';

/// The request methods can throw a [ServerException] with the documented error codes below in addition to the basic
/// [ErrorCodes] of the method [RestClient.sendRequest] which can be thrown in every request!
///
/// Of course the requests can also throw parsing exceptions on converting data themselves!
///
/// A NoteTransfer starts with the [startNoteTransferRequest], then a variable amount of [downloadNoteRequest], or
/// [uploadNoteRequest] calls and finally it completes with a call to [finishNoteTransferRequest].
abstract class RemoteNoteDataSource {
  const RemoteNoteDataSource();

  /// The returned changes (delete, rename) if the [NoteUpdate.noteTransferStatus] indicated that the server had the
  /// newer version of the note should be cached and only be applied at the end of the transfer!
  /// The same applies to the migration from client to server id if the note was newly created on the server!
  ///
  /// Returns [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the  client sends a server note id that doesn't belong to it!
  ///
  /// This needs a logged in account, so it can also throw the errors of [FetchCurrentSessionToken]!
  Future<StartNoteTransferResponse> startNoteTransferRequest(StartNoteTransferRequest request);

  /// Uploads the note content if the [NoteUpdate.noteTransferStatus] from [startNoteTransferRequest] indicated that the
  /// client had the newer version of the note.
  ///
  /// The downloaded bytes should be cached in temporary note files and then moved to the real notes on [finishNoteTransferRequest]
  ///
  /// Returns [ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN] if the client used an invalid transfer token, or if the
  /// server cancelled the note transfer!
  /// Returns [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the client sends an invalid server, or client note id that does
  /// not belong to the clients transfer!
  /// Returns [ErrorCodes.FILE_NOT_FOUND] is returned if the server could not find the note file (also happens by
  /// sending wrong ids)!
  ///
  /// This needs a logged in account, so it can also throw the errors of [FetchCurrentSessionToken]!
  Future<DownloadNoteResponse> downloadNoteRequest(DownloadNoteRequest request);

  /// Downloads the note content if the [NoteUpdate.noteTransferStatus] from [startNoteTransferRequest] indicated that the
  /// server had the newer version of the note.
  ///
  /// Returns [ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN] if the client used an invalid transfer token, or if the
  /// server cancelled the note transfer!
  /// Returns [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the client sends an invalid server, or client note id that does
  /// not belong to the clients transfer. Or if the raw bytes are empty!
  ///
  /// This needs a logged in account, so it can also throw the errors of [FetchCurrentSessionToken]!
  Future<void> uploadNoteRequest(UploadNoteRequest request);

  /// Finishes the transfer from [startNoteTransferRequest] and cancels all other transfers on the server.
  ///
  /// Now all cached changes should be applied here from [startNoteTransferRequest] and [downloadNoteRequest]!
  ///
  /// If [FinishNoteTransferRequest.shouldCancel] is [true], then only this specific note transfer will be cancelled on
  /// the server!
  ///
  /// Returns [ErrorCodes.SERVER_INVALID_NOTE_TRANSFER_TOKEN] if the client used an invalid transfer  token, or if the
  /// server cancelled the note transfer!
  /// Return [ErrorCodes.FILE_NOT_FOUND] if something fails during the transfer finish.
  ///
  /// This needs a logged in account, so it can also throw the errors of [FetchCurrentSessionToken]!
  Future<void> finishNoteTransferRequest(FinishNoteTransferRequestWithTransferToken request);
}

class RemoteNoteDataSourceImpl extends RemoteNoteDataSource {
  final RestClient restClient;

  const RemoteNoteDataSourceImpl({required this.restClient});

  @override
  Future<StartNoteTransferResponse> startNoteTransferRequest(StartNoteTransferRequest request) async {
    final Map<String, dynamic> json =
        await restClient.sendJsonRequest(endpoint: Endpoints.NOTE_TRANSFER_START, bodyData: request.toJson());
    return StartNoteTransferResponse.fromJson(json);
  }

  @override
  Future<DownloadNoteResponse> downloadNoteRequest(DownloadNoteRequest request) async {
    final Map<String, String> queryParams = Map<String, String>.from(request.toJson());
    final ResponseData response = await restClient.sendRequest(
      endpoint: Endpoints.NOTE_DOWNLOAD,
      queryParams: queryParams,
    );
    return DownloadNoteResponse(rawBytes: response.bytes!);
  }

  @override
  Future<void> uploadNoteRequest(UploadNoteRequest request) async {
    final Map<String, String> queryParams = Map<String, String>.from(request.toJson());
    await restClient.sendRequest(endpoint: Endpoints.NOTE_UPLOAD, queryParams: queryParams, bodyData: request.rawBytes);
  }

  @override
  Future<void> finishNoteTransferRequest(FinishNoteTransferRequestWithTransferToken request) async {
    final Map<String, String> queryParams = request.getQueryParams();
    await restClient.sendRequest(
      endpoint: Endpoints.NOTE_TRANSFER_FINISH,
      queryParams: queryParams,
      bodyData: request.toJson(),
    );
  }
}
