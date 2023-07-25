import 'dart:convert';
import 'dart:typed_data';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/domain/usecases/usecase.dart';

import 'helper/app_test_helper.dart';

const int _serverPort = 9196; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

void main() {
  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
  });

  tearDown(() async {
    await testCleanup();
  });

  group("change current structure item tests: ", () {
    setUp(() async {
      await createAndLoginToTestAccount();
      await createSomeTestNotes();
      await sl<FetchNewNoteStructure>().call(const NoParams());
    });

    _testErrors();
    _testValid();
  });
}

void _testErrors() {
  test("throw when current item is not changed", () async {
    expect(() async => sl<ChangeCurrentStructureItem>().call(const ChangeCurrentFolderParam(newName: "newName")),
        throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.CANT_BE_MODIFIED)));
  });

  test("throw when the name is empty ", () async {
    sl<NoteStructureRepository>().currentItem =
        sl<NoteStructureRepository>().root!.getAllNotes()[4]; // index 1 is fourth, index 4 is first
    expect(() async => sl<ChangeCurrentStructureItem>().call(const ChangeCurrentNoteParam(newName: "")),
        throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.INVALID_PARAMS)));
  });

  test("throw when the name contains delimiter ", () async {
    sl<NoteStructureRepository>().currentItem =
        sl<NoteStructureRepository>().root!.getAllNotes()[4]; // index 1 is fourth, index 4 is first
    expect(
        () async => sl<ChangeCurrentStructureItem>().call(ChangeCurrentNoteParam(newName: "1${StructureItem.delimiter}2")),
        throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.INVALID_PARAMS)));
  });

  test("throw when type does not match ", () async {
    sl<NoteStructureRepository>().currentItem =
        sl<NoteStructureRepository>().root!.getAllNotes()[4]; // index 1 is fourth, index 4 is first
    expect(() async => sl<ChangeCurrentStructureItem>().call(const ChangeCurrentFolderParam(newName: "newName")),
        throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.INVALID_PARAMS)));
  });

  test("throw when name is reserved ", () async {
    sl<NoteStructureRepository>().currentItem =
        sl<NoteStructureRepository>().root!.getAllNotes()[4]; // index 1 is fourth, index 4 is first
    expect(
        () async =>
            sl<ChangeCurrentStructureItem>().call(ChangeCurrentFolderParam(newName: StructureItem.rootFolderNames.first)),
        throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.NAME_ALREADY_USED)));
  });

  test("throw when name of folder already exists for same parent", () async {
    sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1
    expect(() async => sl<ChangeCurrentStructureItem>().call(const ChangeCurrentFolderParam(newName: "dir2")),
        throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.NAME_ALREADY_USED)));
  });
}

void _testValid() {
  test("change only name of a note", () async {
    await _defaultNoteTest("firstNew", null);
  });

  test("change only content of a note", () async {
    await _defaultNoteTest("first", Uint8List.fromList(utf8.encode("123456")));
  });

  test("change both of a note", () async {
    await _defaultNoteTest("firstNew", Uint8List.fromList(utf8.encode("123456")));
  });

  test("change a note of a deeper folder", () async {
    sl<NoteStructureRepository>().currentItem =
        sl<NoteStructureRepository>().root!.getAllNotes()[1]; // index 1 is fourth, index 4 is first
    final DateTime oldTime = DateTime.now();
    await Future<void>.delayed(const Duration(milliseconds: 25));

    await sl<ChangeCurrentStructureItem>().call(const ChangeCurrentNoteParam(newName: "fourthNew"));
    final StructureNote current = sl<NoteStructureRepository>().currentItem as StructureNote;

    expect(current.path, "dir1/dir3/fourthNew", reason: "path should match");
    expect(current.lastModified.isAfter(oldTime), true, reason: "should be newer");

    final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
    expect(current.path,
        SecurityUtils.decryptString(account.noteInfoList.last.encFileName, base64UrlEncode(account.decryptedDataKey!)),
        reason: "enc file name should match");

    final List<int> bytes = await sl<LoadNoteContent>().call(LoadNoteContentParams(noteId: current.id));
    expect(bytes, utf8.encode("123"), reason: "bytes should match");

    expect(sl<NoteStructureRepository>().recent!.getChild(0).path, "dir1/dir3/fourthNew",
        reason: "recent should be updated");
  });

  test("change a deeper folder", () async {
    sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getAllNotes()[1].directParent; // dir3
    final DateTime oldTime = DateTime.now();
    await Future<void>.delayed(const Duration(milliseconds: 25));

    await sl<ChangeCurrentStructureItem>().call(const ChangeCurrentFolderParam(newName: "dir3New"));
    final StructureNote currentNote = sl<NoteStructureRepository>().root!.getAllNotes()[1];

    expect(sl<NoteStructureRepository>().currentItem!.name, "dir3New", reason: "folder name updated");
    expect(currentNote.path, "dir1/dir3New/fourth", reason: "path should match");
    expect(currentNote.lastModified.isAfter(oldTime), true, reason: "should be newer");

    final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
    expect(currentNote.path,
        SecurityUtils.decryptString(account.noteInfoList.last.encFileName, base64UrlEncode(account.decryptedDataKey!)),
        reason: "enc file name should match");

    final List<int> bytes = await sl<LoadNoteContent>().call(LoadNoteContentParams(noteId: currentNote.id));
    expect(bytes, utf8.encode("123"), reason: "bytes should match");

    expect(sl<NoteStructureRepository>().recent!.getChild(0).path, "dir1/dir3New/fourth",
        reason: "recent should be updated");
  });

  test("change a note of recent", () async {
    // set current item to child of recent
    sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().recent!.getChild(0);
    final DateTime oldTime = DateTime.now();
    await Future<void>.delayed(const Duration(milliseconds: 25));
    // change the item
    await sl<ChangeCurrentStructureItem>().call(const ChangeCurrentNoteParam(newName: "fourthNew"));

    // get current item again which should be the updated recent child from before
    final StructureNote currentNote = (await sl<GetCurrentStructureItem>().call(const NoParams())) as StructureNote;
    expect(currentNote.path, "dir1/dir3/fourthNew", reason: "path should match");
    expect(currentNote.lastModified.isAfter(oldTime), true, reason: "should be newer");
    expect(currentNote.topMostParent, sl<NoteStructureRepository>().recent, reason: "should still have recent as parent");

    final StructureFolder rootFolder =
        sl<NoteStructureRepository>().getFolderByPath("dir1/dir3", deepCopy: false) as StructureFolder;

    expect(rootFolder.getChild(0).path, currentNote.path, reason: "the item in root should have an equal path");
    expect(rootFolder.getChild(0).topMostParent, isNot(currentNote.topMostParent),
        reason: "but a different top level parent");

    // the locally stored stuff should still match
    final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
    expect(currentNote.path,
        SecurityUtils.decryptString(account.noteInfoList.last.encFileName, base64UrlEncode(account.decryptedDataKey!)),
        reason: "enc file name should match");

    final List<int> bytes = await sl<LoadNoteContent>().call(LoadNoteContentParams(noteId: currentNote.id));
    expect(bytes, utf8.encode("123"), reason: "bytes should match");
  });
}

Future<void> _defaultNoteTest(String newName, Uint8List? newContent) async {
  sl<NoteStructureRepository>().currentItem =
      sl<NoteStructureRepository>().root!.getAllNotes()[4]; // index 1 is fourth, index 4 is first
  final DateTime oldTime = DateTime.now();
  await Future<void>.delayed(const Duration(milliseconds: 25));

  await sl<ChangeCurrentStructureItem>().call(ChangeCurrentNoteParam(newName: newName, newContent: newContent));
  final StructureNote current = sl<NoteStructureRepository>().currentItem as StructureNote;

  expect(current.path, newName, reason: "path should match");
  expect(current.lastModified.isAfter(oldTime), true, reason: "should be newer");

  final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
  expect(current.path,
      SecurityUtils.decryptString(account.noteInfoList.first.encFileName, base64UrlEncode(account.decryptedDataKey!)),
      reason: "enc file name should match");

  final List<int> bytes = await sl<LoadNoteContent>().call(LoadNoteContentParams(noteId: current.id));
  expect(bytes, newContent ?? utf8.encode("123"), reason: "bytes should match");
}
