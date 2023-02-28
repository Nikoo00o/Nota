import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:app/core/enums/note_sorting.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_folders.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/list_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/domain/usecases/usecase.dart';

import '../../../server/test/helper/server_test_helper.dart' as server; // relative import of the server test helpers, so
// that the real server responses can be used for testing instead of mocks! The server tests should be run before!
import '../fetch_new_note_structure_test.dart';
import '../helper/app_test_helper.dart';

const int _serverPort = 9295; // also needs to be a different port for each test file. The app tests dont have to care
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
      await loginToTestAccount();
      await createSomeTestNotes();
      await sl<FetchNewNoteStructure>().call(const NoParams());
    });

    // todo: add more tests for different configurations and also for errors!!!
    // included tests to create folders, to create files. inside root vs inside recent, etc...
    // create a note directly from root dir vs from deeper folder
    // IMPORTANT: this also applies to the other tests inside of the folder structure_changes

    test("creating a new note inside of a subfolder from root", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1

      await sl<CreateStructureItem>().call(const CreateStructureItemParams(name: "fifth", isFolder: false));
      final StructureItem current = await sl<GetCurrentStructureItem>().call(const NoParams());

      expect(current.path, "dir1/fifth", reason: "path of the new note should match");

      final StructureFolder dir1 = sl<NoteStructureRepository>().root!.getChild(0) as StructureFolder;
      expect(dir1.amountOfChildren, 4, reason: "root dir1 should now have 4 children");
      expect(dir1.getChild(2).path, current.path, reason: "the path of the child of dir1 should match");
      expect((dir1.getChild(2) as StructureNote).id, (current as StructureNote).id, reason: "and the note id as well");
      expect(current.directParent?.path, dir1.path, reason: "and the parent reference should also match");

      final ClientAccount account = await sl<GetLoggedInAccount>().call(const NoParams());
      expect(current.path,
          SecurityUtils.decryptString(account.noteInfoList.last.encFileName, base64UrlEncode(account.decryptedDataKey!)),
          reason: "enc file name should match");

      final List<int> bytes = await sl<LoadNoteContent>().call(LoadNoteContentParams(noteId: current.id));
      expect(bytes, utf8.encode(""), reason: "bytes should be empty");

      expect(sl<NoteStructureRepository>().recent!.getChild(0).path, "dir1/fifth", reason: "recent should be updated");
    });
  });
}
