import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/enums/required_login_status.dart';
import 'package:app/core/get_it.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/change/change_account_password.dart';
import 'package:app/domain/usecases/account/change/change_auto_login.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/domain/usecases/account/fetch_current_session_token.dart';
import 'package:app/domain/usecases/account/get_auto_login.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/get_required_login_status.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/domain/usecases/note_transfer/store_note_encrypted.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:server/domain/entities/note_transfer.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/usecases/usecase.dart';

import '../../server/test/helper/server_test_helper.dart' as server; // relative import of the server test helpers, so that
// the real server responses can be used for testing instead of mocks! The server tests should be run before!
import 'helper/app_test_helper.dart';

const int _serverPort = 9193; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

void main() {
  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
  });

  tearDown(() async {
    await testCleanup();
  });

  group("transfer notes tests: ", () {
    test("Basic note transfer should work to store a new note on the server", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await sl<LoginToAccount>().call(const RemoteLoginParams(username: "test1", password: "password1"));
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
          noteId: -1, decryptedName: "name", decryptedContent: Uint8List.fromList(utf8.encode("test"))));

      await sl<TransferNotes>().call(NoParams());

      final Uint8List bytes = await sl<LoadNoteContent>().call(const LoadNoteContentParams(noteId: 1));
      expect(utf8.decode(bytes), "test");

      final ClientAccount account = await sl<GetLoggedInAccount>().call(NoParams());

      account.noteInfoList[0] = account.noteInfoList.first.copyWith(
          newEncFileName: SecurityUtils.encryptString("invalid", base64UrlEncode(account.decryptedDataKey!)),
          newLastEdited: DateTime.now().subtract(const Duration(hours: 1)));

      final bool deleted = await sl<NoteTransferRepository>().deleteNote(noteId: 1);
      expect(deleted, true);
      

      Logger.verbose("next round");

      await sl<TransferNotes>().call(NoParams());

      expect(SecurityUtils.decryptString(account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
          "name");

      final Uint8List bytes2 = await sl<LoadNoteContent>().call(const LoadNoteContentParams(noteId: 1));
      expect(utf8.decode(bytes2), "test");
    });
  });
}
