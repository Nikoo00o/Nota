import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:test/test.dart';
import 'helper/test_helpers.dart';

// test for the specific account functions.

const int _serverPort = 8194;

void main() {
  setUp(() async {
    // will be run for each test!
    await createCommonTestObjects(serverPort: _serverPort); // creates the global test objects.
    // IMPORTANT: this needs a different server port for each test file! (this callback will be run before each test)
  });

  tearDown(() async {
    await cleanupTestFilesAndServer(deleteTestFolderAfterwards: true); // cleanup server and hive test data after every test
    // (this callback will be run after each test)
  });

  group("Note data source tests: ", () {
    test("save and load a file successfully", () async {
      final List<int> bytes = <int>[1, 2, 3, 4];
      await noteDataSource.saveTempNoteData(1, "test", bytes);
      await noteDataSource.replaceNoteDataWithTempData(1, "test");
      final List<int> newBytes = await noteDataSource.loadNoteData(1);
      expect(bytes, newBytes);
    });

    test("throw an exception on reading a note file without replacing it first", () async {
      await noteDataSource.saveTempNoteData(1, "test", <int>[1, 2, 3, 4]);
      expect(() async {
        await noteDataSource.loadNoteData(1);
      }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.FILE_NOT_FOUND));
    });

    test("throw an exception on reading a note file which was already deleted", () async {
      await noteDataSource.saveTempNoteData(1, "test", <int>[1, 2, 3, 4]);
      await noteDataSource.replaceNoteDataWithTempData(1, "test");
      await noteDataSource.deleteNoteData(1);
      expect(() async {
        await noteDataSource.loadNoteData(1);
      }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.FILE_NOT_FOUND));
    });

    test("throw an exception on reading a temp note file which was already deleted", () async {
      await noteDataSource.saveTempNoteData(1, "test", <int>[1, 2, 3, 4]);
      await noteDataSource.deleteNoteData(1, transferToken: "test");
      expect(() async {
        await noteDataSource.replaceNoteDataWithTempData(1, "test");
      }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.FILE_NOT_FOUND));
    });

    test("throw an exception on reading a temp note file which was already cleaned up", () async {
      await noteDataSource.saveTempNoteData(1, "test", <int>[1, 2, 3, 4]);
      await noteDataSource.deleteAllTempNotes();
      expect(() async {
        await noteDataSource.replaceNoteDataWithTempData(1, "test");
      }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.FILE_NOT_FOUND));
    });

    test("throw an exception on reading a temp note file which was already specifically cleaned up", () async {
      await noteDataSource.saveTempNoteData(1, "test", <int>[1, 2, 3, 4]);
      await noteDataSource.deleteAllTempNotes(transferToken: "test");
      expect(() async {
        await noteDataSource.replaceNoteDataWithTempData(1, "test");
      }, throwsA((Object e) => e is ServerException && e.message == ErrorCodes.FILE_NOT_FOUND));
    });

    test("still read a normal file successfully after temp cleanup", () async {
      final List<int> bytes = <int>[1, 2, 3, 4];
      await noteDataSource.saveTempNoteData(1, "test", bytes);
      await noteDataSource.replaceNoteDataWithTempData(1, "test");
      await noteDataSource.deleteAllTempNotes();
      final List<int> newBytes = await noteDataSource.loadNoteData(1);
      expect(bytes, newBytes);
    });
  });
}
