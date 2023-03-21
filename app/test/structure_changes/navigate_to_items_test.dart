import 'dart:async';

import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_update_batch.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_folders.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/domain/usecases/usecase.dart';

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
      await createAndLoginToTestAccount();
      await createSomeTestNotes();
      await sl<FetchNewNoteStructure>().call(const NoParams());
    });

    test("navigating to root top level folder", () async {
      await sl<NavigateToItem>().call(const NavigateToItemParamsTopLevel(topLevelIndex: 0));
      expect(sl<NoteStructureRepository>().currentItem, sl<NoteStructureRepository>().root);
    });

    test("navigating to root top level folder root by name", () async {
      await sl<NavigateToItem>().call(NavigateToItemParamsTopLevelName(folderName: StructureItem.rootFolderNames.first));
      expect(sl<NoteStructureRepository>().currentItem, sl<NoteStructureRepository>().root);
    });

    test("navigating to the first child of root", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root;
      await sl<NavigateToItem>().call(const NavigateToItemParamsChild(childIndex: 0));
      expect(sl<NoteStructureRepository>().currentItem, sl<NoteStructureRepository>().root!.getChild(0));
    });

    test("navigating to the first child folder of root by name", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root;
      await sl<NavigateToItem>().call(const NavigateToItemParamsChildFolderByName(folderName: "dir1"));
      expect(sl<NoteStructureRepository>().currentItem, sl<NoteStructureRepository>().root!.getChild(0));
    });

    test("navigating to the first note of root by id", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root;
      await sl<NavigateToItem>().call(const NavigateToItemParamsChildNoteById(noteId: -1));
      expect(sl<NoteStructureRepository>().currentItem, sl<NoteStructureRepository>().root!.getChild(2));
    });

    test("navigating to the root parent", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0);
      await sl<NavigateToItem>().call(const NavigateToItemParamsParent());
      expect(sl<NoteStructureRepository>().currentItem, sl<NoteStructureRepository>().root);
    });

    test("navigating should also update listeners", () async {
      int listenerCallAmount = 0;
      final StreamSubscription<StructureUpdateBatch> listener1 = await sl<GetStructureUpdatesStream>()
          .call(GetStructureUpdatesStreamParams(callbackFunction: (StructureUpdateBatch updateBatch) {
        // this listener drains the previous events
        listenerCallAmount++;
      }));

      await Future<void>.delayed(const Duration(milliseconds: 50)); // wait for the old events to be drained
      expect(listenerCallAmount, 1, reason: "called once so far");
      StructureItem? currentCompareItem = sl<NoteStructureRepository>().root;

      final StreamSubscription<StructureUpdateBatch> listener2 = await sl<GetStructureUpdatesStream>()
          .call(GetStructureUpdatesStreamParams(callbackFunction: (StructureUpdateBatch updateBatch) {
        // always compare the current item in the listener with the updated compare item. the listener should now receive
        // all events
        expect(currentCompareItem, updateBatch.currentItem, reason: "listener2 item comp");
      }));

      // this will add a new event that calls the expect
      await sl<NavigateToItem>().call(const NavigateToItemParamsTopLevel(topLevelIndex: 0));

      currentCompareItem = (currentCompareItem as StructureFolder).getChild(0);
      await sl<NavigateToItem>().call(const NavigateToItemParamsChild(childIndex: 0));

      await listener1.cancel();

      currentCompareItem = (currentCompareItem as StructureFolder).getChild(1);
      await sl<NavigateToItem>().call(const NavigateToItemParamsChild(childIndex: 1));

      await listener2.cancel();

      // this event should not be received as an update
      await sl<NavigateToItem>().call(const NavigateToItemParamsChild(childIndex: 0));

      expect(listenerCallAmount, 3, reason: "listener1 should have only been called 3 times");
    });

    test("getting top level parents without the move selection should contain all top level folders except move", () async {
      final Map<TranslationString, StructureFolder> folders =
          await sl<GetStructureFolders>().call(const GetStructureFoldersParams(includeMoveFolder: false));
      expect(folders[TranslationString(StructureItem.rootFolderNames.first)]?.isRoot, true, reason: "root");
      expect(folders[TranslationString(StructureItem.recentFolderNames.first)]?.isRecent, true, reason: "recent");
      expect(folders[TranslationString(StructureItem.moveFolderNames.first)]?.isMove, null, reason: "move");
    });
  });
}
