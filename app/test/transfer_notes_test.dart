import 'dart:convert';
import 'dart:typed_data';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/entities/note_content.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/domain/usecases/usecase.dart';

import 'helper/app_test_helper.dart';

const int _serverPort = 9192; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

void main() {
  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
  });

  tearDown(() async {
    await testCleanup();
  });

  group("transfer notes use case: ", () {
    test("no logged in account should throw", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      expect(() async {
        await sl<TransferNotes>().call(const NoParams());
      }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD)),
          reason: "no file");
    });

    test("Store note on server and then download it again", () async {
      final ClientAccount account = await _loginAndCreateNote();
      final DateTime firstTime = account.noteInfoList.first.lastEdited;

      dialogServiceMock.confirmedOverride = true; // should confirm the note transfer
      await sl<TransferNotes>().call(const NoParams()); // first transfer to upload note

      // change note name to something else, but the server should have the newer version
      account.noteInfoList[0] = account.noteInfoList.first.copyWith(
          newEncFileName: SecurityUtils.encryptString("invalid", base64UrlEncode(account.decryptedDataKey!)),
          newLastEdited: DateTime.now().subtract(const Duration(hours: 1)));

      final bool deleted = await sl<NoteTransferRepository>().deleteNote(noteId: 1);
      expect(deleted, true, reason: "note file should be deleted"); // only delete the note file

      await sl<TransferNotes>().call(const NoParams()); //next transfer to download note

      expect(account.noteInfoList.length, 1, reason: "account should have 1 note");
      expect(
        SecurityUtils.decryptString(account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
        "name",
        reason: "should have the old file name",
      );
      expect(account.noteInfoList.first.lastEdited, firstTime, reason: "should have the old time stamp");

      final List<int> bytes2 = await loadNoteBytes(noteId: 1, noteType: NoteType.RAW_TEXT);
      expect(utf8.decode(bytes2), "test", reason: "should have the old note bytes downloaded again");
    });

    test("Store note on server and then cancel the transfer", () async {
      final ClientAccount account = await _loginAndCreateNote();

      dialogServiceMock.confirmedOverride = true; // dont cancel the first note transfer
      await sl<TransferNotes>().call(const NoParams()); // first transfer to upload note

      final DateTime newTime = DateTime.now().subtract(const Duration(hours: 1));
      // change note name to something else, but the server should have the newer version
      account.noteInfoList[0] = account.noteInfoList.first.copyWith(
          newEncFileName: SecurityUtils.encryptString("invalid", base64UrlEncode(account.decryptedDataKey!)),
          newLastEdited: newTime);

      final bool deleted = await sl<NoteTransferRepository>().deleteNote(noteId: 1);
      expect(deleted, true, reason: "note file should be deleted"); // only delete the note file

      dialogServiceMock.confirmedOverride = false; // should cancel the note transfer
      await sl<TransferNotes>().call(const NoParams()); //next transfer to download note

      expect(account.noteInfoList.length, 1, reason: "account should have 1 note");
      expect(
        SecurityUtils.decryptString(account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
        "invalid",
        reason: "should have the new file name",
      );
      expect(account.noteInfoList.first.lastEdited, newTime, reason: "should have the new time stamp");

      expect(() async {
        await loadNoteBytes(noteId: 1, noteType: NoteType.RAW_TEXT);
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)),
          reason: "no file");
    });

    test("Should do nothing without notes", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());

      dialogServiceMock.confirmedOverride = true; // dont cancel
      await sl<TransferNotes>().call(const NoParams());

      expect(account.noteInfoList.isEmpty, true, reason: "account should have no notes");
    });

    test("Store note on server and then upload it again", () async {
      final ClientAccount account = await _loginAndCreateNote();

      dialogServiceMock.confirmedOverride = true; // should confirm the note transfer
      await sl<TransferNotes>().call(const NoParams()); // first transfer to upload note

      // newer version on client
      final DateTime nextTime = await sl<StoreNoteEncrypted>().call(ChangeNoteEncryptedParams(
        noteId: 1,
        decryptedName: "invalid",
        decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("file"), noteType: NoteType.RAW_TEXT),
      ));

      await sl<TransferNotes>().call(const NoParams()); //next transfer to upload note again

      expect(account.noteInfoList.length, 1, reason: "account should have 1 note");
      expect(
        SecurityUtils.decryptString(account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
        "invalid",
        reason: "should have the new file name",
      );
      expect(account.noteInfoList.first.lastEdited, nextTime, reason: "should have the mew time stamp");

      final List<int> bytes2 = await loadNoteBytes(noteId: 1, noteType: NoteType.RAW_TEXT);
      expect(utf8.decode(bytes2), "file", reason: "should have the new note bytes");
    });

    test("Transfer with same note should do nothing", () async {
      final ClientAccount account = await _loginAndCreateNote();
      final DateTime firstTime = account.noteInfoList.first.lastEdited;

      dialogServiceMock.confirmedOverride = true; // should confirm the note transfer
      await sl<TransferNotes>().call(const NoParams()); // first transfer to upload note

      await sl<TransferNotes>().call(const NoParams()); //next transfer to download note

      expect(account.noteInfoList.length, 1, reason: "account should have 1 note");
      expect(
        SecurityUtils.decryptString(account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
        "name",
        reason: "should have the old file name",
      );
      expect(account.noteInfoList.first.lastEdited, firstTime, reason: "should have the old time stamp");

      final List<int> bytes2 = await loadNoteBytes(noteId: 1, noteType: NoteType.RAW_TEXT);
      expect(utf8.decode(bytes2), "test", reason: "should have the old note bytes downloaded again");
    });
  });

  test("Transfer after logout, so the client does not have the notes and needs to download again", () async {
    ClientAccount account = await _loginAndCreateNote();
    final DateTime firstTime = account.noteInfoList.first.lastEdited;

    dialogServiceMock.confirmedOverride = true; // should confirm the note transfer
    await sl<TransferNotes>().call(const NoParams()); // first transfer to upload note

    account.username = "dontCacheData"; // pretend that this is someone else, so that the logout does not cache!
    await sl<LogoutOfAccount>().call(const LogoutOfAccountParams(navigateToLoginPage: false)); //resets the account
    await loginToTestAccount();
    account = await sl<GetLoggedInAccount>().call(const NoParams()); //refresh account because of logout

    await sl<TransferNotes>().call(const NoParams()); //next transfer to download note

    expect(account.noteInfoList.length, 1, reason: "account should have 1 note");
    expect(
      SecurityUtils.decryptString(account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
      "name",
      reason: "should have the old file name",
    );
    expect(account.noteInfoList.first.lastEdited, firstTime, reason: "should have the old time stamp");

    final List<int> bytes2 = await loadNoteBytes(noteId: 1, noteType: NoteType.RAW_TEXT);
    expect(utf8.decode(bytes2), "test", reason: "should have the old note bytes downloaded again");
  });

  test("Delete note on client and send to server side", () async {
    final ClientAccount account = await _loginAndCreateNote();

    dialogServiceMock.confirmedOverride = true; // should confirm the note transfer
    await sl<TransferNotes>().call(const NoParams()); // first transfer to upload note

    final DateTime secondTime = await sl<StoreNoteEncrypted>().call(DeleteNoteEncryptedParams(noteId: 1)); //delete note
    await sl<TransferNotes>().call(const NoParams()); //next transfer to send deleted note

    expect(account.noteInfoList.length, 1, reason: "account should have 1 note");
    expect(account.noteInfoList.first.encFileName, "", reason: "name should be empty");
    expect(account.noteInfoList.first.lastEdited, secondTime, reason: "should have the new time stamp");

    expect(() async {
      await loadNoteBytes(noteId: 1, noteType: NoteType.RAW_TEXT);
    }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)),
        reason: "no file");
  });

  test("Delete note on server side and delete local note as well", () async {
    final ClientAccount account = await _loginAndCreateNote();

    dialogServiceMock.confirmedOverride = true; // should confirm the note transfer
    await sl<TransferNotes>().call(const NoParams()); // first transfer to upload note

    final DateTime secondTime = await sl<StoreNoteEncrypted>().call(DeleteNoteEncryptedParams(noteId: 1)); //delete note
    await sl<TransferNotes>().call(const NoParams()); //next transfer to send deleted note

    expect(account.noteInfoList.length, 1, reason: "account should have 1 note");
    expect(account.noteInfoList.first.encFileName, "", reason: "name should be empty");
    expect(account.noteInfoList.first.lastEdited, secondTime, reason: "should have the new time stamp");

    expect(() async {
      await loadNoteBytes(noteId: 1, noteType: NoteType.RAW_TEXT);
    }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)),
        reason: "no file");
  });

  test("Directly sending the server a deleted note", () async {
    final ClientAccount account = await _loginAndCreateNote();
    final DateTime secondTime =
        await sl<StoreNoteEncrypted>().call(DeleteNoteEncryptedParams(noteId: -1)); //delete note

    dialogServiceMock.confirmedOverride = true; // should confirm the note transfer
    await sl<TransferNotes>().call(const NoParams()); // first transfer to upload note

    expect(account.noteInfoList.length, 1, reason: "account should have 1 note");
    expect(account.noteInfoList.first.encFileName, "", reason: "name should be empty");
    expect(account.noteInfoList.first.lastEdited, secondTime, reason: "should have the new time stamp");

    expect(() async {
      await loadNoteBytes(noteId: 1, noteType: NoteType.RAW_TEXT);
    }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)),
        reason: "no file");
  });

  test("Getting a deleted note from the server with cached data", () async {
    ClientAccount account = await _loginAndCreateNote();
    dialogServiceMock.confirmedOverride = true; // should confirm the note transfers
    final String oldName = account.noteInfoList.first.encFileName;

    await sl<TransferNotes>().call(const NoParams()); // first transfer the note and logout while caching
    await sl<LogoutOfAccount>().call(const LogoutOfAccountParams(navigateToLoginPage: false));

    final DateTime deleteTime = DateTime.now(); //then login again and delete the note
    await loginToTestAccount(reuseOldNotes: true);
    account = await sl<GetLoggedInAccount>().call(const NoParams()); //refresh account because of logout
    account.noteInfoList[0] = account.noteInfoList.first.copyWith(newEncFileName: "", newLastEdited: deleteTime);

    await sl<TransferNotes>().call(const NoParams()); // transfer the deleted note to the server

    account.username = "dontCacheData"; // pretend that this is someone else, so that the logout does not cache!
    await sl<LogoutOfAccount>().call(const LogoutOfAccountParams(navigateToLoginPage: false));
    await loginToTestAccount(reuseOldNotes: true);
    account = await sl<GetLoggedInAccount>()
        .call(const NoParams()); //refresh account because of logout and get the old cached
    // data

    expect(account.noteInfoList.length, 1, reason: "first account should have 1 note");
    expect(account.noteInfoList.first.encFileName, oldName, reason: "first name should be the old name");
    await loadNoteBytes(noteId: 1, noteType: NoteType.RAW_TEXT); // and the file should also exist

    await sl<TransferNotes>().call(const NoParams()); // now from this transfer the note should get deleted

    expect(account.noteInfoList.length, 1, reason: "account should still have 1 note");
    expect(account.noteInfoList.first.encFileName, "", reason: "but name should be empty");
    expect(account.noteInfoList.first.lastEdited, deleteTime, reason: "should have the new time stamp");

    expect(() async {
      await loadNoteBytes(noteId: 1, noteType: NoteType.RAW_TEXT);
    }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)),
        reason: "no file");
  });

  test("Directly getting a deleted note from the server", () async {
    ClientAccount account = await _loginAndCreateNote();
    dialogServiceMock.confirmedOverride = true; // should confirm the note transfers
    final DateTime deletedTime = DateTime.now().add(const Duration(hours: 1));

    // modify the note as if it was deleted
    account.noteInfoList[0] = account.noteInfoList.first.copyWith(newEncFileName: "", newLastEdited: deletedTime);

    await sl<TransferNotes>().call(const NoParams()); // first transfer the deleted note and logout without caching
    account.username = "dontCacheData";
    await sl<LogoutOfAccount>().call(const LogoutOfAccountParams(navigateToLoginPage: false));

    await loginToTestAccount();
    account = await sl<GetLoggedInAccount>().call(const NoParams()); //refresh account because of logout

    await sl<TransferNotes>().call(const NoParams()); // transfer the deleted note to the server

    account.username = "dontCacheData"; // pretend that this is someone else, so that the logout does not cache!
    await sl<LogoutOfAccount>().call(const LogoutOfAccountParams(navigateToLoginPage: false));
    await loginToTestAccount();
    account = await sl<GetLoggedInAccount>().call(const NoParams()); //refresh account because of logout

    expect(account.noteInfoList.length, 0, reason: "account has no note before");
    await sl<TransferNotes>().call(const NoParams()); // this transfer should now get the deleted note data

    expect(account.noteInfoList.length, 1, reason: "account should have 1 note");
    expect(account.noteInfoList.first.encFileName, "", reason: "name should be empty");
    expect(account.noteInfoList.first.lastEdited, deletedTime, reason: "should have the new time stamp");

    expect(() async {
      await loadNoteBytes(noteId: 1, noteType: NoteType.RAW_TEXT);
    }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)),
        reason: "no file");
  });
}

Future<ClientAccount> _loginAndCreateNote() async {
  await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
  await loginToTestAccount();
  await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
    noteId: -1,
    decryptedName: "name",
    decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("test"), noteType: NoteType.RAW_TEXT),
  ));
  final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
  return account;
}
