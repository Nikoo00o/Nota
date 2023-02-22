import 'dart:convert';
import 'dart:typed_data';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/domain/usecases/note_transfer/store_note_encrypted.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/domain/usecases/usecase.dart';

import '../../server/test/helper/server_test_helper.dart' as server; // relative import of the server test helpers, so that
// the real server responses can be used for testing instead of mocks! The server tests should be run before!
import 'helper/app_test_helper.dart';

const int _serverPort = 9194; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

void main() {
    setUp(() async {
        await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
    });

    tearDown(() async {
        await testCleanup();
    });

    group("fetch new note structure use case: ", () {

    });
}
