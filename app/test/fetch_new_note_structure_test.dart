import 'dart:convert';
import 'dart:typed_data';
import 'package:app/core/enums/note_sorting.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_folders.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/list_utils.dart';
import 'package:shared/domain/usecases/usecase.dart';

import 'helper/app_test_helper.dart';

const int _serverPort = 9194; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

/// this test also tests the use cases [GetCurrentStructureItem] and [GetStructureFolders] and [UpdateNoteStructure].

void main() {
  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
  });

  tearDown(() async {
    await testCleanup();
  });

  group("fetch new note structure use case: ", () {
    group("no account: ", _testWithoutAccount);
    group("logged in account: ", _testWithAccount);
  });
}

void _testWithoutAccount() {
  test("fetch new structure should throw with no account", () async {
    expect(() async => sl<FetchNewNoteStructure>().call(const NoParams()),
        throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.CLIENT_NO_ACCOUNT)));
  });

  test("same throw with no account and get current structure item", () async {
    expect(() async => sl<GetCurrentStructureItem>().call(const NoParams()),
        throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.CLIENT_NO_ACCOUNT)));
  });

  test("other throw with no logged in account and get current structure folders", () async {
    await sl<CreateAccount>().call(const CreateAccountParams(username: "test1", password: "password1"));
    expect(() async => sl<GetStructureFolders>().call(const GetStructureFoldersParams(includeMoveFolder: true)),
        throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD)));
  });
}

void _testWithAccount() {
  setUp(() async {
    await createAndLoginToTestAccount();
  });

  test("update note without fetch new structure should throw ", () async {
    expect(() async => sl<UpdateNoteStructure>().call(UpdateNoteStructureParams(originalItem: null)),
        throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.INVALID_PARAMS)));
  });

  test("fetching a simple new note structure should work and also call update note structure ", () async {
    await _testSimpleNoteStructure(callFetchNewStructure: true);
  });

  test("the same should also work the same without an explicit call to fetch the new structure ", () async {
    await _testSimpleNoteStructure(callFetchNewStructure: false);
  });

  test("the complex structure should be build correctly ", () async {
    await _testComplexStructure();
  });

  group("test changes: ", _testChanges);
}

Future<void> _testSimpleNoteStructure({required bool callFetchNewStructure}) async {
  await sl<StoreNoteEncrypted>().call(CreateNoteEncryptedParams(
      noteId: -1,
      decryptedName: "name",
      decryptedContent: Uint8List.fromList(utf8.encode("test")),
      noteType: NoteType.RAW_TEXT));

  if (callFetchNewStructure) {
    await sl<FetchNewNoteStructure>().call(const NoParams());
  }

  final StructureItem item = await sl<GetCurrentStructureItem>().call(const NoParams());
  final List<StructureFolder> folders = await getStructureFoldersAsList();

  expect(folders[0].isRoot, true, reason: "root true");
  expect(folders[0].sorting, NoteSorting.BY_NAME, reason: "name sorting");
  expect(folders[0].canBeModified, false, reason: "not modifiable");

  expect(item, folders[0], reason: "current should be root");
  expect(folders[1].isRecent, true, reason: "recent true");
  expect(folders[1].sorting, NoteSorting.BY_DATE, reason: "name sorting");
  expect(folders[1].canBeModified, false, reason: "not modifiable");

  expect(folders[0].amountOfChildren, folders[1].amountOfChildren, reason: "same children");
  expect(folders[0].amountOfChildren, 1, reason: "1 child");
  expect(folders[0].getChild(0).name, folders[1].getChild(0).name, reason: "same child name");
  expect(folders[0].getChild(0).directParent, isNot(folders[1].getChild(0).directParent),
      reason: "but different parents");

  expect(folders[0].getChild(0).name, "name", reason: "note name match");
  expect((folders[0].getChild(0) as StructureNote).id, -1, reason: "note id match");
  expect(folders[0].getChild(0).directParent, folders[0], reason: "parent of root child should be root");
  expect(folders[1].getChild(0).directParent, folders[1],
      reason: "the parent of a direct recent child should be recent");
}

Future<void> _testComplexStructure() async {
  await createSomeTestNotes();

  final List<StructureFolder> folders = await getStructureFoldersAsList();
  final StructureFolder root = folders[0];
  final StructureFolder recent = folders[1];

  final List<StructureNote> rootNotes = root.getAllNotes();
  final List<StructureNote> recentNotes = recent.getAllNotes();

  // first test root
  expect(root.amountOfChildren, 3, reason: "3 children of root");
  expect(rootNotes.length, 5, reason: "but all root notes should have length 5");

  expect(root.getChild(0).name, "dir1", reason: "first child is dir1");
  expect(root.getChild(1).name, "dir2", reason: "second child is dir2");
  expect(root.getChild(2).name, "first", reason: "third child is the note");

  final StructureFolder subFolder = root.getChild(0) as StructureFolder;
  final StructureFolder deepestFolder = subFolder.getChild(1) as StructureFolder;

  expect(subFolder.canBeModified, true, reason: "subfolder should be modifiable");
  expect(subFolder.sorting, NoteSorting.BY_NAME, reason: "subfolder correct sorting");
  expect(subFolder.amountOfChildren, 3, reason: "subfolder 3 children");

  expect(deepestFolder.name, "dir3", reason: "second child of subfolder is dir3");
  expect(subFolder.getChild(2).name, "second", reason: "last child of subfolder is second");
  expect((root.getChild(1) as StructureFolder).getChild(0).name, "second", reason: "dir2 should also have a second");
  expect(subFolder.getChild(2).name, "second", reason: "last child of subfolder is second");

  expect(deepestFolder.getChild(0).name, "fourth", reason: "dir3 should have fourth");
  expect(deepestFolder.getChild(0).directParent, deepestFolder, reason: "fourth should have correct parent");

  expect(deepestFolder.directParent, subFolder, reason: "dir3 should have correct parent");
  expect(deepestFolder.directParent, deepestFolder.getParent(), reason: "for root get parent should match: 1/2");
  expect(deepestFolder.getChild(0).directParent, deepestFolder.getChild(0).getParent(),
      reason: "for root get parent should match: 2/2");

  // then test recent
  expect(recent.amountOfChildren, 5, reason: "5 children of recent");
  expect(recentNotes.length, 5, reason: "all recent notes should also have length 5");

  expect(recent.getChild(0).name, "fourth", reason: "first child is most recent");
  expect(recent.getChild(4).name, "first", reason: "last child is oldest");

  expect(recent.getChild(0).directParent?.path, deepestFolder.path,
      reason: "fourth should have correct direct parent folder for recent");
  expect(recent.getChild(0).getParent(), recent,
      reason: "but the getParent() should return recent as the top most folder");

  expect(recent.getChild(3).directParent!.directParent, recent,
      reason: "in recent the direct parent of dir1 should be recent itself!");
  expect(recent.getChild(4).directParent, recent,
      reason: "in recent the direct parent of first should be recent itself!");
  expect(recent.getChild(0).directParent!.getParent(), recent,
      reason: "getParent() should also work for a folder in recent");

  // then test notes and paths
  expect(deepestFolder.path, "dir1/dir3", reason: "dir3 should have correct path");
  final List<String> rootPaths = rootNotes.map((StructureNote note) => note.path).toList();
  final List<String> recentPaths = recentNotes.map((StructureNote note) => note.path).toList();

  expect(rootPaths.first, "dir1/a_third", reason: "root first path should be third");
  expect(rootPaths.last, "first", reason: "root last path should be first");
  expect(rootPaths[2], "dir1/second", reason: "root third path should be second1");

  expect(recentPaths.first, "dir1/dir3/fourth", reason: "recent first path should be fourth");
  expect(recentPaths[2], "dir2/second", reason: "recent third path should be second2");

  rootPaths.sort();
  recentPaths.sort();
  expect(ListUtils.equals(rootPaths, recentPaths), true, reason: "root and recent note paths should be same");
}

void _testChanges() {
  setUp(() async {
    await createSomeTestNotes();
  });

  test("changing current item of root and fetching new structure", () async {
    final List<StructureFolder> folders = await getStructureFoldersAsList();
    final StructureFolder root = folders[0];
    sl<NoteStructureRepository>().currentItem = (root.getChild(0) as StructureFolder).getChild(0);

    await sl<FetchNewNoteStructure>().call(const NoParams());
    final StructureItem currentItem = await sl<GetCurrentStructureItem>().call(const NoParams());
    expect(currentItem.path, "dir1/a_third");
  });

  test("changing current item of recent and fetching new structure", () async {
    final List<StructureFolder> folders = await getStructureFoldersAsList();
    final StructureFolder recent = folders[1];
    sl<NoteStructureRepository>().currentItem = recent.getChild(1);

    await sl<FetchNewNoteStructure>().call(const NoParams());
    final StructureItem currentItem = await sl<GetCurrentStructureItem>().call(const NoParams());
    expect(currentItem.path, "dir1/a_third");
  });

  test("get notes by id and folders by path / name", () async {
    final List<StructureFolder> folders = await getStructureFoldersAsList();
    final StructureFolder root = folders[0];
    final StructureFolder recent = folders[1];

    final StructureNote? n1 = root.getNoteById(-5);
    final StructureNote? n2 = recent.getNoteById(-5);

    expect(n1?.path, n2?.path, reason: "notes should have same path");
    expect(n1?.id, n2?.id, reason: "notes should have same id");
    expect(n1?.topMostParent, isNot(n2?.topMostParent), reason: "but notes should have different top level parent");
    expect(n1?.path, "dir1/dir3/fourth", reason: "should be the correct note");

    final StructureFolder? f1 = root.getFolderByPath("dir1/dir3", deepCopy: true);
    final StructureFolder? f2 =
        root.getDirectFolderByName("dir1", deepCopy: true)?.getDirectFolderByName("dir3", deepCopy: true);
    expect(f1, f2, reason: "Should be same folder");
    expect(f1?.path, "dir1/dir3", reason: "should be the correct folder");
  });

  test("the parent of note should still get correctly matched to root, or recent after updating", () async {
    List<StructureFolder> folders = await getStructureFoldersAsList();
    sl<NoteStructureRepository>().currentItem = folders[0].getChild(2);

    await sl<FetchNewNoteStructure>().call(const NoParams());
    StructureItem currentItem = await sl<GetCurrentStructureItem>().call(const NoParams());
    folders = await getStructureFoldersAsList();

    expect(currentItem.path, "first", reason: "name should match");
    expect(currentItem.directParent, folders[0], reason: "parent should be root first");

    sl<NoteStructureRepository>().currentItem = folders[1].getChild(4); // switch current item to child of recent
    await sl<FetchNewNoteStructure>().call(const NoParams());
    currentItem = await sl<GetCurrentStructureItem>().call(const NoParams());
    folders = await getStructureFoldersAsList();

    expect(currentItem.path, "first", reason: "name should still match");
    expect(currentItem.directParent, folders[1], reason: "parent should be recent now");
  });
}

Future<List<StructureFolder>> getStructureFoldersAsList() async {
  final Map<TranslationString, StructureFolder> folders =
      await sl<GetStructureFolders>().call(const GetStructureFoldersParams(includeMoveFolder: true));
  return <StructureFolder>[
    folders[TranslationString(StructureItem.rootFolderNames.first)]!,
    folders[TranslationString(StructureItem.recentFolderNames.first)]!,
    folders[TranslationString(StructureItem.moveFolderNames.first)]!,
  ];
}
