import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/security_utils.dart';
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

  group("Store and load note use cases: ", () {
    test("Load note with no logged in account should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      expect(() async {
        await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
            noteId: -1, decryptedName: "name", decryptedContent: Uint8List.fromList(utf8.encode("test"))));
      }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD)));
    });

    test("Store note with no logged in account should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      expect(() async {
        await sl<LoadNoteContent>().call(const LoadNoteContentParams(noteId: -1));
      }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD)));
    });

    test("Load note with no stored note should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      expect(() async {
        await sl<LoadNoteContent>().call(const LoadNoteContentParams(noteId: -1));
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)));
    });

    test("Load note with an invalid note id should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
          noteId: -1, decryptedName: "name", decryptedContent: Uint8List.fromList(utf8.encode("test"))));
      expect(() async {
        await sl<LoadNoteContent>().call(const LoadNoteContentParams(noteId: -100));
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)));
    });

    test("Creating a note with an empty filename should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();

      expect(() async {
        await sl<StoreNoteEncrypted>()
            .call(CreateNoteEncryptedParams(noteId: -1, decryptedName: "", decryptedContent: Uint8List(0)));
      }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.INVALID_PARAMS)));
    });

    test("Store and load note with an valid note id should work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
          noteId: -1, decryptedName: "name", decryptedContent: Uint8List.fromList(utf8.encode("test"))));
      final List<int> bytes = await sl<LoadNoteContent>().call(const LoadNoteContentParams(noteId: -1));
      expect(utf8.decode(bytes), "test", reason: "bytes should match");
    });

    test("Creating a note twice should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
          noteId: -1, decryptedName: "name", decryptedContent: Uint8List.fromList(utf8.encode("test"))));
      expect(() async {
        await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
            noteId: -1, decryptedName: "name", decryptedContent: Uint8List.fromList(utf8.encode("test"))));
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)));
    });

    test("Changing a note when there is none should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      expect(() async {
        await sl<StoreNoteEncrypted>().call(ChangeNoteEncryptedParams(
            noteId: -1, decryptedName: "name", decryptedContent: Uint8List.fromList(utf8.encode("test"))));
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)));
    });

    test("Deleting a note when there is none should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      expect(() async {
        await sl<StoreNoteEncrypted>().call(DeleteNoteEncryptedParams(noteId: -1));
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)));
    });

    test("Notes should also be deleted", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
          noteId: -1, decryptedName: "name", decryptedContent: Uint8List.fromList(utf8.encode("test"))));
      await sl<StoreNoteEncrypted>().call(DeleteNoteEncryptedParams(noteId: -1));

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      expect(account.noteInfoList.first.isDeleted, true, reason: "note should be marked as deleted");

      expect(() async {
        await sl<LoadNoteContent>().call(const LoadNoteContentParams(noteId: -1));
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)));
    });

    test("Notes should also be changed", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
          noteId: -1, decryptedName: "name", decryptedContent: Uint8List.fromList(utf8.encode("test"))));

      await sl<StoreNoteEncrypted>().call(ChangeNoteEncryptedParams(
          noteId: -1, decryptedName: "diff", decryptedContent: Uint8List.fromList(utf8.encode("bytes"))));

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      final List<int> bytes = await sl<LoadNoteContent>().call(const LoadNoteContentParams(noteId: -1));
      expect("diff",
          SecurityUtils.decryptString(account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
          reason: "file name should match");
      expect(utf8.decode(bytes), "bytes", reason: "bytes should match");
    });

    test("Changing a note with an empty filename should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();

      expect(() async {
        await sl<StoreNoteEncrypted>()
            .call(ChangeNoteEncryptedParams(noteId: -1, decryptedName: "", decryptedContent: Uint8List(0)));
      }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.INVALID_PARAMS)));
    });

    test("Changing a note with no values should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();

      expect(() async {
        await sl<StoreNoteEncrypted>()
            .call(ChangeNoteEncryptedParams(noteId: -1, decryptedContent: null, decryptedName: null));
      }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.INVALID_PARAMS)));
    });

    test("Changing a note with only an empty content should work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
          noteId: -1, decryptedName: "name", decryptedContent: Uint8List.fromList(utf8.encode("test"))));

     final DateTime time = await sl<StoreNoteEncrypted>()
          .call(ChangeNoteEncryptedParams(noteId: -1, decryptedName: null, decryptedContent: Uint8List(0)));

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      final List<int> bytes = await sl<LoadNoteContent>().call(const LoadNoteContentParams(noteId: -1));
      expect("name",
          SecurityUtils.decryptString(account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
          reason: "file name should match");
      expect(utf8.decode(bytes), "", reason: "bytes should match");
      expect(account.noteInfoList.first.lastEdited, time, reason: "time should match");
    });

    test("Changing a note with only a filename should work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
          noteId: -1, decryptedName: "name", decryptedContent: Uint8List.fromList(utf8.encode("test"))));

      final DateTime time = await sl<StoreNoteEncrypted>()
          .call(ChangeNoteEncryptedParams(noteId: -1, decryptedName: "file", decryptedContent: null));

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      final List<int> bytes = await sl<LoadNoteContent>().call(const LoadNoteContentParams(noteId: -1));
      expect("file",
          SecurityUtils.decryptString(account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
          reason: "file name should match");
      expect(utf8.decode(bytes), "test", reason: "bytes should match");
      expect(account.noteInfoList.first.lastEdited, time, reason: "time should match");
    });
  });
}
