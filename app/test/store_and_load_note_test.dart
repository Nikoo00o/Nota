import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:app/core/get_it.dart';
import 'package:app/data/datasources/file_picker_data_source.dart.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/entities/file_picker_result.dart';
import 'package:app/domain/entities/note_content/note_content.dart';
import 'package:app/domain/repositories/external_file_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/domain/usecases/usecase.dart';

import 'fixtures/fixture_reader.dart';
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

  _testExternalFileRepository();
  return;
  _testNoteContent();
  _testStoreNoteUseCases();
}

void _testExternalFileRepository() {
  group("external file repository tests: ", () {
    test("no paths set", () async {
      final ExternalFileRepository repo = sl<ExternalFileRepository>();
      expect(await repo.getImportFileInfo(), null, reason: "import should be null");
      expect(await repo.getExportFilePath(dialogTitle: "test", fileName: "test"), null,
          reason: "export should be null");
    });

    test("txt file write/load extensive tests", () async {
      final ExternalFileRepository repo = sl<ExternalFileRepository>();
      final String importPath = fixturePath("test.txt");
      filePickerDataSourceMock.importPath = importPath;
      final String exportPath = "$testResourceFolder${Platform.pathSeparator}text_test.txt";
      filePickerDataSourceMock.exportPath = exportPath;

      final FilePickerResult? result = await repo.getImportFileInfo();
      expect(await repo.getExportFilePath(dialogTitle: "", fileName: ""), exportPath, reason: "export path match");
      expect(result?.path, importPath, reason: "path match");
      expect(result?.size, 97, reason: "size match");
      expect(result?.lastModified.toIso8601String(), "2023-10-29T14:49:38.000", reason: "date match");

      // compression should not matter for txt files
      final Uint8List bytes = await repo.loadExternalFileCompressed(path: importPath, compression: 7);
      expect(bytes.length, result?.size, reason: "size of bytes should match");
      expect(utf8.decode(bytes), fixture("test.txt", removeFormatting: false), reason: "content should match");

      await repo.saveExternalFile(path: exportPath, bytes: bytes);
      filePickerDataSourceMock.importPath = exportPath;
      final FilePickerResult? exported = await repo.getImportFileInfo();
      expect(result?.size, exported?.size, reason: "size equal");
      expect(exported!.lastModified.isAfter(DateTime.now().subtract(const Duration(minutes: 1))), true,
          reason: "modified is in last minute");
    });

    test("png test", () async {
      await imageTest("png_test.png", 2894, "2023-10-29T15:33:46.000");
    });

    test("jpg test", () async {
      await imageTest("jpg_test.jpg", 22466, "2023-10-29T15:34:11.000");
    });

    test("unsupported test", () async {
      final ExternalFileRepository repo = sl<ExternalFileRepository>();
      expect(() async {
        filePickerDataSourceMock.importPath = fixturePath("notSupported.notSupported");
        await repo.getImportFileInfo();
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_SUPPORTED)));

      expect(() async {
        filePickerDataSourceMock.exportPath = fixturePath("notSupported.notSupported");
        await repo.getExportFilePath(dialogTitle: "test", fileName: "notSupported.notSupported");
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_SUPPORTED)));
    });
  });
}

Future<void> imageTest(String imageName, int size, String dateTime) async {
  final ExternalFileRepository repo = sl<ExternalFileRepository>();
  final String importPath = fixturePath(imageName);
  final String exportPath = "$testResourceFolder${Platform.pathSeparator}$imageName";
  filePickerDataSourceMock.exportPath = exportPath;

  final FilePickerResult? result = await repo.getImportFileInfo(pathOverride: importPath);
  expect(result?.path, importPath, reason: "path match");
  expect(result?.size, size, reason: "size match");
  expect(result?.lastModified.toIso8601String(), dateTime, reason: "date match");

  final Uint8List unCompressedBytes = await repo.loadExternalFileCompressed(path: importPath, compression: 0);
  final Uint8List compressedBytes = await repo.loadExternalFileCompressed(path: importPath, compression: 9);
  expect(unCompressedBytes.length, result?.size, reason: "size of bytes should match");
  expect(compressedBytes.length < unCompressedBytes.length, true, reason: "compressed should be less");

  await repo.saveExternalFile(path: exportPath, bytes: compressedBytes);
  final FilePickerResult? exported = await repo.getImportFileInfo(pathOverride: exportPath);
  expect(compressedBytes.length, exported?.size, reason: "size equal");
}

void _testNoteContent() {
  group("note content tests: ", () {
    test("raw text file", () async {
      const String data = "test ü";
      final NoteContentRawText saved =
          NoteContent.saveFile(decryptedContent: utf8.encode(data), noteType: NoteType.RAW_TEXT) as NoteContentRawText;
      expect(saved.version, NoteContentRawText.RAW_TEXT_VERSION, reason: "save version match");
      expect(saved.headerSize, NoteContentRawText.staticHeaderSize, reason: "save header size match");
      expect(saved.textSize, utf8.encode(data).length, reason: "save text size match");
      expect(saved.textSize, saved.text.length, reason: "text size should also be same as length of text");
      expect(saved.fullBytes.length, saved.textSize + saved.headerSize, reason: "bytes should be text + header big");
      expect(utf8.decode(saved.text), data, reason: "save content match");

      final NoteContentRawText loaded =
          NoteContent.loadFile(bytes: saved.fullBytes, noteType: NoteType.RAW_TEXT) as NoteContentRawText;
      expect(loaded.version, NoteContentRawText.RAW_TEXT_VERSION, reason: "load version match");
      expect(loaded.headerSize, NoteContentRawText.staticHeaderSize, reason: "load header size match");
      expect(loaded.textSize, utf8.encode(data).length, reason: "load text size match");
      expect(utf8.decode(loaded.text), data, reason: "load content match");

      expect(listEquals(saved.fullBytes, loaded.fullBytes), true, reason: "bytes of both should match");
    });

    test("empty raw text file", () async {
      final NoteContentRawText saved =
          NoteContent.saveFile(decryptedContent: <int>[], noteType: NoteType.RAW_TEXT) as NoteContentRawText;
      expect(saved.isEmpty, true, reason: "save is empty");
      expect(saved.fullBytes.isEmpty, false, reason: "save bytes are still not empty");
      expect(saved.headerSize, NoteContentRawText.staticHeaderSize, reason: "save header size match");

      final NoteContentRawText loaded =
          NoteContent.loadFile(bytes: saved.fullBytes, noteType: NoteType.RAW_TEXT) as NoteContentRawText;
      expect(loaded.isEmpty, true, reason: "load is empty");
      expect(loaded.fullBytes.isEmpty, false, reason: "load bytes are still not empty");
      expect(loaded.headerSize, NoteContentRawText.staticHeaderSize, reason: "load header size match");
    });

    test("file wrapper test", () async {
      const String data = "bytes";
      const String path = "test/example.png";
      const int size = 1000;
      final DateTime modified = DateTime(2023, 10, 1, 2, 3, 5); // Datetime.now would remove 3 last milliseconds and
      // fail
      final NoteContentFileWrapper saved = NoteContent.saveFile(
        decryptedContent: utf8.encode(data),
        noteType: NoteType.FILE_WRAPPER,
        fileWrapperParams:
            FileWrapperParams(fileInfo: FilePickerResult(lastModified: modified, path: path, size: size)),
      ) as NoteContentFileWrapper;

      expect(saved.version, NoteContentFileWrapper.FILE_WRAPPER_VERSION, reason: "save version match");
      expect(saved.headerSize, NoteContentFileWrapper.staticHeaderSize, reason: "save header size match");
      expect(saved.contentSize, utf8.encode(data).length, reason: "save content size match");
      expect(saved.contentSize, saved.content.length, reason: "content size should also be same as length of data");
      expect(saved.fullBytes.length, saved.headerSize + saved.pathSize + saved.contentSize,
          reason: "bytes should be header + path + content long");
      expect(utf8.decode(saved.content), data, reason: "save content match");
      expect(saved.text.length, 0, reason: "save text empty");
      expect(saved.pathSize, utf8.encode(path).length, reason: "save path size match");
      expect(saved.path, path, reason: "save path match");
      expect(saved.externalFileSize, size, reason: "save externalFileSize match");
      expect(saved.fileLastModified, modified, reason: "save lastModifiedTime match");

      final NoteContentFileWrapper loaded =
          NoteContent.loadFile(bytes: saved.fullBytes, noteType: NoteType.FILE_WRAPPER) as NoteContentFileWrapper;
      expect(loaded.version, NoteContentFileWrapper.FILE_WRAPPER_VERSION, reason: "load version match");
      expect(loaded.headerSize, NoteContentFileWrapper.staticHeaderSize, reason: "load header size match");
      expect(loaded.contentSize, utf8.encode(data).length, reason: "load content size match");
      expect(utf8.decode(loaded.content), data, reason: "load content match");

      expect(listEquals(saved.fullBytes, loaded.fullBytes), true, reason: "bytes of both should match");
      expect(() async {
        NoteContent.saveFile(decryptedContent: utf8.encode("data"), noteType: NoteType.FILE_WRAPPER);
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.INVALID_PARAMS)));
    });
  });
}

void _testStoreNoteUseCases() {
  group("Store and load note use cases: ", () {
    test("Load note with no logged in account should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      expect(() async {
        await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
          noteId: -1,
          decryptedName: "name",
          decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("test"), noteType: NoteType.RAW_TEXT),
        ));
      }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD)));
    });

    test("Store note with no logged in account should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      expect(() async {
        await loadNoteBytes(noteId: -1, noteType: NoteType.RAW_TEXT);
      }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD)));
    });

    test("Load note with no stored note should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      expect(() async {
        await loadNoteBytes(noteId: -1, noteType: NoteType.RAW_TEXT);
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)));
    });

    test("Load note with an invalid note id should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
        noteId: -1,
        decryptedName: "name",
        decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("test"), noteType: NoteType.RAW_TEXT),
      ));
      expect(() async {
        await loadNoteBytes(noteId: -100, noteType: NoteType.RAW_TEXT);
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)));
    });

    test("Creating a note with an empty filename should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();

      expect(() async {
        await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
          noteId: -1,
          decryptedName: "",
          decryptedContent: NoteContent.saveFile(decryptedContent: <int>[], noteType: NoteType.RAW_TEXT),
        ));
      }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.INVALID_PARAMS)));
    });

    test("Store and load note with an valid note id should work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
        noteId: -1,
        decryptedName: "name",
        decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("test"), noteType: NoteType.RAW_TEXT),
      ));
      final List<int> bytes = await loadNoteBytes(noteId: -1, noteType: NoteType.RAW_TEXT);
      expect(utf8.decode(bytes), "test", reason: "bytes should match");
    });

    test("Creating a note twice should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
        noteId: -1,
        decryptedName: "name",
        decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("test"), noteType: NoteType.RAW_TEXT),
      ));
      expect(() async {
        await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
          noteId: -1,
          decryptedName: "name",
          decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("test"), noteType: NoteType.RAW_TEXT),
        ));
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)));
    });

    test("Changing a note when there is none should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      expect(() async {
        await sl<StoreNoteEncrypted>().call(ChangeNoteEncryptedParams(
          noteId: -1,
          decryptedName: "name",
          decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("test"), noteType: NoteType.RAW_TEXT),
        ));
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
        noteId: -1,
        decryptedName: "name",
        decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("test"), noteType: NoteType.RAW_TEXT),
      ));
      await sl<StoreNoteEncrypted>().call(DeleteNoteEncryptedParams(noteId: -1));

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      expect(account.noteInfoList.first.isDeleted, true, reason: "note should be marked as deleted");

      expect(() async {
        await loadNoteBytes(noteId: -1, noteType: NoteType.RAW_TEXT);
      }, throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)));
    });

    test("Notes should also be changed", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
        noteId: -1,
        decryptedName: "name",
        decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("test"), noteType: NoteType.RAW_TEXT),
      ));

      await sl<StoreNoteEncrypted>().call(ChangeNoteEncryptedParams(
        noteId: -1,
        decryptedName: "diff",
        decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("bytes"), noteType: NoteType.RAW_TEXT),
      ));

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      final List<int> bytes = await loadNoteBytes(noteId: -1, noteType: NoteType.RAW_TEXT);
      expect(
          "diff",
          SecurityUtils.decryptString(
              account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
          reason: "file name should match");
      expect(utf8.decode(bytes), "bytes", reason: "bytes should match");
    });

    test("Changing a note with an empty filename should not work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();

      expect(() async {
        await sl<StoreNoteEncrypted>().call(ChangeNoteEncryptedParams(
          noteId: -1,
          decryptedName: "",
          decryptedContent: NoteContent.saveFile(decryptedContent: <int>[], noteType: NoteType.RAW_TEXT),
        ));
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
        noteId: -1,
        decryptedName: "name",
        decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("test"), noteType: NoteType.RAW_TEXT),
      ));

      final DateTime time = await sl<StoreNoteEncrypted>().call(ChangeNoteEncryptedParams(
        noteId: -1,
        decryptedName: null,
        decryptedContent: NoteContent.saveFile(decryptedContent: <int>[], noteType: NoteType.RAW_TEXT),
      ));

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      final List<int> bytes = await loadNoteBytes(noteId: -1, noteType: NoteType.RAW_TEXT);
      expect(
          "name",
          SecurityUtils.decryptString(
              account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
          reason: "file name should match");
      expect(utf8.decode(bytes), "", reason: "bytes should match");
      expect(account.noteInfoList.first.lastEdited, time, reason: "time should match");
    });

    test("Changing a note with only a filename should work", () async {
      await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
      await loginToTestAccount();
      await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
        noteId: -1,
        decryptedName: "name",
        decryptedContent: NoteContent.saveFile(decryptedContent: utf8.encode("test"), noteType: NoteType.RAW_TEXT),
      ));

      final DateTime time = await sl<StoreNoteEncrypted>()
          .call(ChangeNoteEncryptedParams(noteId: -1, decryptedName: "file", decryptedContent: null));

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      final List<int> bytes = await loadNoteBytes(noteId: -1, noteType: NoteType.RAW_TEXT);
      expect(
          "file",
          SecurityUtils.decryptString(
              account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
          reason: "file name should match");
      expect(utf8.decode(bytes), "test", reason: "bytes should match");
      expect(account.noteInfoList.first.lastEdited, time, reason: "time should match");
    });
  });
}
