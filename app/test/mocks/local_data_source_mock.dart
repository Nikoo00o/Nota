import 'dart:typed_data';

import 'package:app/data/datasources/local_data_source.dart';

class LocalDataSourceMock extends LocalDataSource {
  Map<String, String> hiveStorage = <String, String>{};
  Map<String, String> secureStorage = <String, String>{};

  /// The file paths mapped to the byte lists.
  Map<String, Uint8List> files = <String, Uint8List>{};

  @override
  Future<void> init() async {}

  @override
  Future<String> getNoteFilePath(int noteId) async => noteId.toString();

  @override
  Future<void> write({required String key, required String? value, required bool secure}) async {
    if (value == null) {
      return delete(key: key, secure: secure);
    }
    if (secure == false) {
      hiveStorage[key] = value;
    } else {
      secureStorage[key] = value;
    }
  }

  @override
  Future<String?> read({required String key, required bool secure}) async {
    if (secure == false) {
      return hiveStorage[key];
    } else {
      return secureStorage[key];
    }
  }

  @override
  Future<void> delete({required String key, required bool secure}) async {
    if (secure == false) {
      hiveStorage.remove(key);
    } else {
      secureStorage.remove(key);
    }
  }

  @override
  Future<void> writeFile({required String filePath, required List<int> bytes}) async {
    files[filePath] = Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List?> readFile({required String filePath}) async {
    return files[filePath];
  }

  @override
  Future<bool> deleteFile({required String filePath}) async {
    final bool contained = files.containsKey(filePath);
    files.remove(filePath);
    return contained;
  }
}
