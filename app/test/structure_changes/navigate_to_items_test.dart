import 'package:app/core/get_it.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/domain/usecases/usecase.dart';

import '../../../server/test/helper/server_test_helper.dart' as server; // relative import of the server test helpers, so
// that the real server responses can be used for testing instead of mocks! The server tests should be run before!
import '../fetch_new_note_structure_test.dart';
import '../helper/app_test_helper.dart';

const int _serverPort = 9292; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

// this contains the use cases navigate to child, parent and top_level

void main() {
  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
  });

  tearDown(() async {
    await testCleanup();
  });

  group("navigate to structure items tests: ", () {
    setUp(() async {
      await loginToTestAccount();
      await createSomeTestNotes();
      await sl<FetchNewNoteStructure>().call(const NoParams());
    });

    test("navigating to root top level folder", () async {
      await sl<NavigateToItem>().call(const NavigateToItemParamsTopLevel(topLevelIndex: 0));
      expect(sl<NoteStructureRepository>().currentItem, sl<NoteStructureRepository>().root);
    });

    test("navigating to the first child of root", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root;
      await sl<NavigateToItem>().call(const NavigateToItemParamsChild(childIndex: 0));
      expect(sl<NoteStructureRepository>().currentItem, sl<NoteStructureRepository>().root!.getChild(0));
    });

    test("navigating to the root parent", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0);
      await sl<NavigateToItem>().call(const NavigateToItemParamsParent());
      expect(sl<NoteStructureRepository>().currentItem, sl<NoteStructureRepository>().root);
    });
  });
}
