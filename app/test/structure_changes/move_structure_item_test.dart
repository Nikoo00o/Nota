import 'dart:convert';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_structure/finish_move_structure_item.dart';
import 'package:app/domain/usecases/note_structure/start_move_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/usecases/usecase.dart';

import '../helper/app_test_helper.dart';

const int _serverPort = 9293; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

// this contains the use cases start and finish move structure

void main() {
  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
  });

  tearDown(() async {
    await testCleanup();
  });

  group("move structure item tests: ", () {
    setUp(() async {
      await createAndLoginToTestAccount();
      await createSomeTestNotes();
      await sl<FetchNewNoteStructure>().call(const NoParams());
    });

    // todo: also test all errors, cancelling ,etc. also test moving a folder into itself

    test("moving a deeper folder of root to another deeper folder", () async {
      final DateTime before = DateTime.now();
      await Future<void>.delayed(const Duration(milliseconds: 25));
      sl<NoteStructureRepository>().currentItem =
          (sl<NoteStructureRepository>().root!.getChild(0) as StructureFolder).getChild(1); // dir1/dir3

      await sl<StartMoveStructureItem>().call(const NoParams()); //start move for dir3
      StructureFolder currentFolder = sl<NoteStructureRepository>().currentItem as StructureFolder;

      expect(currentFolder.isMove, true, reason: "current item should now be move selection");
      expect(currentFolder.amountOfChildren, 2, reason: "move selection should only have the 2 folders");
      sl<NoteStructureRepository>().currentItem = currentFolder.getChild(1); // select dir2 as target for the move

      await sl<FinishMoveStructureItem>().call(const FinishMoveStructureItemParams(wasConfirmed: true)); // finish move
      currentFolder = sl<NoteStructureRepository>().currentItem as StructureFolder; // update current folder

      expect(currentFolder.topMostParent.isRoot, true, reason: "current item should be a subfolder of root again");
      expect(currentFolder.path, "dir2/dir3", reason: "folder path should be updated");

      final StructureFolder? invalid = sl<NoteStructureRepository>().root?.getFolderByPath("dir1/dir3", deepCopy: false);
      final StructureFolder? valid = sl<NoteStructureRepository>().root?.getFolderByPath("dir2/dir3", deepCopy: false);
      expect(invalid, null, reason: "the old folder path should be moved and invalid");
      expect(currentFolder, valid, reason: "but the new folder path should be valid");

      expect(currentFolder.amountOfChildren, 1, reason: "folder should still have its child");
      final StructureNote note = currentFolder.getChild(0) as StructureNote;
      expect(note.path, "dir2/dir3/fourth", reason: "and the note should have an updated path");
      final StructureNote? validNote = sl<NoteStructureRepository>().root?.getNoteById(note.id);
      expect(note, validNote, reason: "and should be found with root");

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      final NoteInfo noteInfo = account.noteInfoList.firstWhere((NoteInfo noteInfo) => noteInfo.id == note.id);

      expect(noteInfo.lastEdited.isAfter(before), true, reason: "the time stamp should also be newer");
      expect(note.path, SecurityUtils.decryptString(noteInfo.encFileName, base64UrlEncode(account.decryptedDataKey!)),
          reason: "enc file name should match");

      final List<int> bytes = await loadNoteBytes(noteId: note.id, noteType: note.noteType);
      expect(bytes, utf8.encode("123"), reason: "bytes should be still the same");

      expect(sl<NoteStructureRepository>().recent!.amountOfChildren, 5,
          reason: "recent should have same amount of children");
      expect(sl<NoteStructureRepository>().recent!.getChild(0).path, "dir2/dir3/fourth",
          reason: "but recent should have the new path as well");
    });
  });
}
