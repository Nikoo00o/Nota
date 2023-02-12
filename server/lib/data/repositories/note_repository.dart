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
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/dtos/account/account_change_password_request.dart';
import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/domain/entities/note_info.dart';
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

  String _getTransactionToken(RestCallbackParams params) => params.queryParams[RestJsonParameter.TRANSFER_TOKEN] ?? "";
}
