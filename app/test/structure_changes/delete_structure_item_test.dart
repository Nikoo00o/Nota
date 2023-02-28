import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/note_structure/delete_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/usecases/usecase.dart';

import '../../../server/test/helper/server_test_helper.dart' as server; // relative import of the server test helpers, so
// that the real server responses can be used for testing instead of mocks! The server tests should be run before!
import '../fetch_new_note_structure_test.dart';
import '../helper/app_test_helper.dart';

const int _serverPort = 9294; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

void main() {
  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
  });

  tearDown(() async {
    await testCleanup();
  });

  group("delete structure item tests: ", () {
    setUp(() async {
      await loginToTestAccount();
      await createSomeTestNotes();
      await sl<FetchNewNoteStructure>().call(const NoParams());
    });

    test("deleting a deeper folder of root", () async {
      sl<NoteStructureRepository>().currentItem =
          (sl<NoteStructureRepository>().root!.getChild(0) as StructureFolder).getChild(1); // dir1/dir3

      final StructureNote deletedNote =
          (sl<NoteStructureRepository>().currentItem as StructureFolder).getChild(0) as StructureNote; // fourth

      await sl<DeleteCurrentStructureItem>().call(const NoParams());
      final StructureItem current = await sl<GetCurrentStructureItem>().call(const NoParams());

      expect(current.path, "dir1", reason: "path should now be dir1");
      expect((current as StructureFolder).amountOfChildren, 2, reason: "dir1 should have only 2 children");

      final StructureFolder? folder = sl<NoteStructureRepository>().root!.getFolderByPath("dir1/dir3", deepCopy: false);
      expect(folder, null, reason: "the folder should no longer exists for root");

      final StructureNote? newNote = sl<NoteStructureRepository>().root!.getNoteById(deletedNote.id);
      expect(newNote, null, reason: "the note should also no longer exists for root");

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      final NoteInfo noteInfo = account.noteInfoList.firstWhere((NoteInfo note) => note.id == deletedNote.id);
      expect(noteInfo.encFileName.isEmpty, true, reason: "account should have empty filename for note");

      expect(
        () async {
          await sl<LoadNoteContent>().call(LoadNoteContentParams(noteId: deletedNote.id));
        },
        throwsA(predicate((Object e) => e is FileException && e.message == ErrorCodes.FILE_NOT_FOUND)),
        reason: "file should not exist anymore",
      );

      expect(sl<NoteStructureRepository>().recent!.amountOfChildren, 4, reason: "recent should be updated as well");
    });
  });
}
