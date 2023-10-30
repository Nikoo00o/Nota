import 'dart:convert';
import 'dart:io';
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
import 'package:app/domain/usecases/note_structure/export_current_structure_item.dart';
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

const int _serverPort = 9294; // also needs to be a different port for each test file. The app tests dont have to care
// about the server errors!

void main() {
  setUp(() async {
    await createCommonTestObjects(serverPort: _serverPort); // init all helper objects
  });

  tearDown(() async {
    await testCleanup();
  });

  group("export current structure item tests: ", () {
    setUp(() async {
      await createAndLoginToTestAccount();
      await createSomeTestNotes();
      await sl<FetchNewNoteStructure>().call(const NoParams());
    });

    test("export a default note to a txt file", () async {
      sl<NoteStructureRepository>().currentItem =
          (sl<NoteStructureRepository>().root!.getChild(0) as StructureFolder).getChild(0); // dir1/a_third
      await sl<GetCurrentStructureItem>().call(const NoParams());

      const String data = "some test note";
      await sl<ChangeCurrentStructureItem>()
          .call(ChangeCurrentNoteParam(newName: "content", newContent: utf8.encode(data)));
      filePickerDataSourceMock.exportPath = "$testResourceFolder${Platform.pathSeparator}exported.txt";
      await sl<ExportCurrentStructureItem>().call(const NoParams());

      final File file = File(filePickerDataSourceMock.exportPath!);
      final String content = await file.readAsString();
      expect(content, data, reason: "txt file content should match");
    });

    test("export a folder should not work", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1
      await sl<GetCurrentStructureItem>().call(const NoParams());

      filePickerDataSourceMock.exportPath = "$testResourceFolder${Platform.pathSeparator}exported.txt";
      expect(() async {
        await sl<ExportCurrentStructureItem>().call(const NoParams());
      }, throwsA(predicate((Object e) => e is ClientException && e.message == ErrorCodes.INVALID_PARAMS)),
          reason: "export should fail");
    });

    test("export a file wrapper to a png file", () async {
      sl<NoteStructureRepository>().currentItem = sl<NoteStructureRepository>().root!.getChild(0); // dir1
      filePickerDataSourceMock.importPath = fixturePath("png_test.png");

      await sl<CreateStructureItem>()
          .call(const CreateStructureItemParams(name: "fifth", noteType: NoteType.FILE_WRAPPER));
      await sl<GetCurrentStructureItem>().call(const NoParams());

      filePickerDataSourceMock.exportPath = "$testResourceFolder${Platform.pathSeparator}exported.png";
      await sl<ExportCurrentStructureItem>().call(const NoParams());

      final File file = File(filePickerDataSourceMock.exportPath!);
      expect(file.existsSync(), true, reason: "png file should exist");
    });
  });
}
