import 'dart:io';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/account_data_source.dart.dart';
import 'package:server/data/datasources/note_data_source.dart';
import 'package:server/data/models/server_account_model.dart';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/core/network/rest_callback.dart';
import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
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

  Future<RestCallbackResult> handleCreateNoteTransaction(RestCallbackParams params) async {
    // first create the note transaction

    throw UnimplementedError();
  }
}
