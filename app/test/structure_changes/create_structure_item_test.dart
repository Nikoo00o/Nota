import 'dart:convert';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/entities/note_content/note_content.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/domain/usecases/usecase.dart';

import '../fixtures/fixture_reader.dart';
import '../helper/app_test_helper.dart';

const int _serverPort = 9296; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

void main() {
  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
  });

  tearDown(() async {
    await testCleanup();
  });

  group("create structure item tests: ", () {
    setUp(() async {
      await createAndLoginToTestAccount();
      await createSomeTestNotes();
      await sl<FetchNewNoteStructure>().call(const NoParams());
    });

    // todo: add more tests for different configurations and also for errors!!!
    // included tests to create folders, to create files. inside root vs inside recent, etc...
    // create a note directly from root dir vs from deeper folder
    // also write a test for the load all structure content use case for searching (with default note and empty
    // file wrapper note)

    test("creating a new note inside of a subfolder from root", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1

      await sl<CreateStructureItem>().call(const CreateStructureItemParams(name: "fifth", noteType: NoteType.RAW_TEXT));
      final StructureItem current = await sl<GetCurrentStructureItem>().call(const NoParams());

      expect(current.path, "dir1/fifth", reason: "path of the new note should match");

      final StructureFolder dir1 = sl<NoteStructureRepository>().root!.getChild(0) as StructureFolder;
      expect(dir1.amountOfChildren, 4, reason: "root dir1 should now have 4 children");
      expect(dir1.getChild(2).path, current.path, reason: "the path of the child of dir1 should match");
      expect((dir1.getChild(2) as StructureNote).id, (current as StructureNote).id, reason: "and the note id as well");
      expect(current.directParent?.path, dir1.path, reason: "and the parent reference should also match");

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      expect(
        current.path,
        SecurityUtils.decryptString(account.noteInfoList.last.encFileName, base64UrlEncode(account.decryptedDataKey!)),
        reason: "enc file name should match",
      );

      final List<int> bytes = await loadNoteBytes(noteId: current.id, noteType: current.noteType);
      expect(bytes, utf8.encode(""), reason: "bytes should be empty");

      expect(sl<NoteStructureRepository>().recent!.getChild(0).path, "dir1/fifth", reason: "recent should be updated");
    });

    test("creating a new note inside of recent", () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().recent!;
      await sl<CreateStructureItem>().call(const CreateStructureItemParams(name: "fifth", noteType: NoteType.RAW_TEXT));
      final StructureItem current = await sl<GetCurrentStructureItem>().call(const NoParams());
      expect(current.path, "fifth", reason: "path of the new note should match");

      final StructureFolder recent = sl<NoteStructureRepository>().recent!;
      expect(recent.amountOfChildren, 6, reason: "recent should now have 6 children");

      expect((recent.getChild(0) as StructureNote).id, (current as StructureNote).id,
          reason: "the new note should be the newest");
      expect(current.topMostParent.isRecent, true, reason: "current should also exist in recent");

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      expect(
          current.path,
          SecurityUtils.decryptString(
              account.noteInfoList.last.encFileName, base64UrlEncode(account.decryptedDataKey!)),
          reason: "enc file name should match");

      final List<int> bytes = await loadNoteBytes(noteId: current.id, noteType: current.noteType);
      expect(bytes, utf8.encode(""), reason: "bytes should be empty");

      expect(sl<NoteStructureRepository>().root!.getChild(2).path, "fifth", reason: "root should be updated");
    });

    test("creating a new folder inside of a subfolder from root", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1

      await sl<CreateStructureItem>().call(const CreateStructureItemParams(name: "fold", noteType: NoteType.FOLDER));
      final StructureItem current = await sl<GetCurrentStructureItem>().call(const NoParams());

      expect(current.path, "dir1/fold", reason: "path of the new note should match");

      final StructureFolder dir1 = sl<NoteStructureRepository>().root!.getChild(0) as StructureFolder;
      expect(dir1.amountOfChildren, 4, reason: "root dir1 should now have 4 children");
      expect(dir1.getChild(2).path, current.path, reason: "the path of the child of dir1 should match");
      expect(current.directParent?.path, dir1.path, reason: "and the parent reference should also match");
      expect(dir1.getChild(2) is StructureFolder, true, reason: "and it should be a folder");
    });

    test("creating a new file wrapper around a txt file inside of a subfolder from root", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1
      filePickerDataSourceMock.importPath = fixturePath("test.txt");

      await sl<CreateStructureItem>()
          .call(const CreateStructureItemParams(name: "fifth", noteType: NoteType.FILE_WRAPPER));
      StructureItem current = await sl<GetCurrentStructureItem>().call(const NoParams());

      expect(current.path, "dir1/fifth", reason: "path of the new note should match");

      final StructureFolder dir1 = sl<NoteStructureRepository>().root!.getChild(0) as StructureFolder;
      expect(dir1.amountOfChildren, 4, reason: "root dir1 should now have 4 children");
      expect(dir1.getChild(2).path, current.path, reason: "the path of the child of dir1 should match");
      expect(current.directParent?.path, dir1.path, reason: "and the parent reference should also match");
      expect((dir1.getChild(2) as StructureNote).id, (current as StructureNote).id, reason: "and the note id as well");
      expect(current.noteType, NoteType.RAW_TEXT, reason: "and note type should be raw text");
      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      expect(
        current.path,
        SecurityUtils.decryptString(account.noteInfoList.last.encFileName, base64UrlEncode(account.decryptedDataKey!)),
        reason: "enc file name should match",
      );

      final List<int> bytes = await loadNoteBytes(noteId: current.id, noteType: current.noteType);
      expect(bytes, utf8.encode(fixture("test.txt", removeFormatting: false)), reason: "bytes should match fixture");

      expect(sl<NoteStructureRepository>().recent!.getChild(0).path, "dir1/fifth", reason: "recent should be updated");

      await sl<ChangeCurrentStructureItem>().call(const ChangeCurrentNoteParam(newName: "fourthNew"));
      current = sl<NoteStructureRepository>().currentItem as StructureNote;
      expect(current.path, "dir1/fourthNew", reason: "change should work with imported text file");

      await sl<ChangeCurrentStructureItem>().call(const ChangeCurrentNoteParam(newName: "empty", newContent: <int>[]));
    });

    test("creating a new file wrapper around a png file inside of a subfolder from root", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1
      filePickerDataSourceMock.importPath = fixturePath("png_test.png");

      await sl<CreateStructureItem>()
          .call(const CreateStructureItemParams(name: "fifth", noteType: NoteType.FILE_WRAPPER));
      StructureItem current = await sl<GetCurrentStructureItem>().call(const NoParams());

      expect(current.path, "dir1/fifth", reason: "path of the new note should match");

      final StructureFolder dir1 = sl<NoteStructureRepository>().root!.getChild(0) as StructureFolder;
      expect(dir1.amountOfChildren, 4, reason: "root dir1 should now have 4 children");
      expect(dir1.getChild(2).path, current.path, reason: "the path of the child of dir1 should match");
      expect(current.directParent?.path, dir1.path, reason: "and the parent reference should also match");
      expect((dir1.getChild(2) as StructureNote).id, (current as StructureNote).id, reason: "and the note id as well");
      expect(current.noteType, NoteType.FILE_WRAPPER, reason: "and note type should be file wrapper");
      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      expect(
        current.path,
        SecurityUtils.decryptString(account.noteInfoList.last.encFileName, base64UrlEncode(account.decryptedDataKey!)),
        reason: "enc file name should match",
      );

      final NoteContentFileWrapper content = (await sl<LoadNoteContent>()
          .call(LoadNoteContentParams(noteId: current.id, noteType: current.noteType))) as NoteContentFileWrapper;
      expect(content.text.isEmpty, true, reason: "text should be empty");
      expect(content.path, filePickerDataSourceMock.importPath, reason: "imported path should match");
      expect(content.contentSize, 3277, reason: "content size should match with correct app config compression lvl");

      expect(sl<NoteStructureRepository>().recent!.getChild(0).path, "dir1/fifth", reason: "recent should be updated");

      await sl<ChangeCurrentStructureItem>().call(const ChangeCurrentNoteParam(newName: "fourthNew"));
      current = sl<NoteStructureRepository>().currentItem as StructureNote;
      expect(current.path, "dir1/fourthNew", reason: "change name should work with imported file wrapper");

      expect(() async {
        await sl<ChangeCurrentStructureItem>()
            .call(const ChangeCurrentNoteParam(newName: "empty", newContent: <int>[]));
      }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.INVALID_PARAMS)),
          reason: "change content should not work with imported file wrapper");
    });
  });
}
