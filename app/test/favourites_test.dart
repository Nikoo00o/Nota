import 'dart:convert';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/entities/favourites.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/favourites/change_favourite.dart';
import 'package:app/domain/usecases/favourites/get_favourites.dart';
import 'package:app/domain/usecases/favourites/is_favourite.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/domain/usecases/usecase.dart';

import 'helper/app_test_helper.dart';

const int _serverPort = 9195; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

void main() {
  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
  });

  tearDown(() async {
    await testCleanup();
  });

  group("favourite tests: ", () {
    setUp(() async {
      await createAndLoginToTestAccount();
      await createSomeTestNotes();
      await sl<FetchNewNoteStructure>().call(const NoParams());
    });

    // todo: add more tests for different configurations and also for errors!!!

    test("change and is favourite tests", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1
      final StructureFolder dir1 = sl<NoteStructureRepository>().currentItem as StructureFolder;
      final StructureNote note1 = dir1.getChild(0) as StructureNote; // a_third

      expect(await sl<IsFavourite>().call(IsFavouriteParams.fromItem(dir1)), false,
          reason: "fav false first for folder ");
      expect(await sl<IsFavourite>().call(IsFavouriteParams.fromNoteId(note1.id)), false,
          reason: "fav false first for note ");

      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: true, item: dir1));
      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: true, item: note1));

      expect(await sl<IsFavourite>().call(IsFavouriteParams.fromItem(dir1)), true, reason: "fav true now for folder ");
      expect(await sl<IsFavourite>().call(IsFavouriteParams.fromNoteId(note1.id)), true,
          reason: "fav true now for note ");

      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: false, item: dir1));
      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: false, item: note1));

      expect(await sl<IsFavourite>().call(IsFavouriteParams.fromItem(dir1)), false,
          reason: "fav false again for folder ");
      expect(await sl<IsFavourite>().call(IsFavouriteParams.fromNoteId(note1.id)), false,
          reason: "fav false again for note ");
    });

    test("get favourites tests", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1
      final StructureFolder dir1 = sl<NoteStructureRepository>().currentItem as StructureFolder;
      final StructureNote note1 = dir1.getChild(0) as StructureNote; // a_third

      Favourites favourites = await sl<GetFavourites>().call(const NoParams());
      expect(favourites.favourites.isEmpty, true, reason: "first no favourites");

      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: true, item: dir1));
      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: true, item: note1));

      favourites = await sl<GetFavourites>().call(const NoParams());
      expect(favourites.favourites.length == 2, true, reason: "now two favourites");
      expect(favourites.favourites[0].name == "dir1", true, reason: "first fav is dir1");
      expect(favourites.favourites[1].name == "a_third", true, reason: "second fav is a_third");

      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: false, item: dir1));
      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: false, item: note1));

      favourites = await sl<GetFavourites>().call(const NoParams());
      expect(favourites.favourites.isEmpty, true, reason: "now zero favourites");
    });

    test("logout should remove favourites", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1
      StructureFolder dir1 = sl<NoteStructureRepository>().currentItem as StructureFolder;
      StructureNote note1 = dir1.getChild(0) as StructureNote; // a_third

      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: true, item: dir1));
      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: true, item: note1));

      await sl<LogoutOfAccount>().call(const LogoutOfAccountParams(navigateToLoginPage: false)); //logout and then init

      await loginToTestAccount(reuseOldNotes: true);
      await sl<FetchNewNoteStructure>().call(const NoParams());
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1
      dir1 = sl<NoteStructureRepository>().currentItem as StructureFolder;
      note1 = dir1.getChild(0) as StructureNote; // a_third

      final Favourites favourites = await sl<GetFavourites>().call(const NoParams());
      expect(favourites.favourites.isEmpty, true, reason: "after logout there should be no favourites");
    });

    test("update favourite on transfer note test", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1
      final StructureFolder dir1 = sl<NoteStructureRepository>().currentItem as StructureFolder;
      final StructureNote note1 = dir1.getChild(0) as StructureNote; // a_third

      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: true, item: dir1));
      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: true, item: note1));

      await sl<TransferNotes>().call(const NoParams());
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1
      final StructureFolder newDir1 = sl<NoteStructureRepository>().currentItem as StructureFolder;
      final StructureNote newNote1 = newDir1.getChild(0) as StructureNote; // a_third

      expect(newDir1.path == dir1.path, true, reason: "folder path is same");
      expect(newNote1.path == note1.path, true, reason: "note path is same");
      expect(newNote1.id == note1.id, false, reason: "note id is different");

      Favourites favourites = await sl<GetFavourites>().call(const NoParams());
      expect(favourites.favourites.length == 2, true, reason: "two favourites");
      expect(favourites.favourites[0] is FolderFavourite, true, reason: "first is folder favourite");
      expect(favourites.favourites[1] is NoteFavourite, true, reason: "second is note favourite");
      expect((favourites.favourites[0] as FolderFavourite).path == newDir1.path, true, reason: "folder has same path");
      expect((favourites.favourites[1] as NoteFavourite).id == newNote1.id, true, reason: "note has new id");

      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: false, item: newDir1));
      await sl<ChangeFavourite>().call(ChangeFavouriteParams(isFavourite: false, item: newNote1));

      favourites = await sl<GetFavourites>().call(const NoParams());
      expect(favourites.favourites.isEmpty, true, reason: "now it still chagnes to zero favourites");
    });
  });
}
