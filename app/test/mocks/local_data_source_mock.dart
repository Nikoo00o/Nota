import 'dart:math';
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
  Future<void> writeFile({required String localFilePath, required List<int> bytes}) async {
    files[localFilePath] = Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List?> readFile({required String localFilePath}) async {
    return files[localFilePath];
  }

  @override
  Future<bool> deleteFile({required String localFilePath}) async {
    final bool contained = files.containsKey(localFilePath);
    files.remove(localFilePath);
    return contained;
  }

  @override
  Future<bool> renameFile({required String oldLocalFilePath, required String newLocalFilePath}) async {
    if (files.containsKey(oldLocalFilePath) == false) {
      return false;
    }
    final Uint8List bytes = files.remove(oldLocalFilePath)!;
    files[newLocalFilePath] = bytes;

    return true;
  }

  @override
  Future<List<String>> getFilePaths({required String subFolderPath}) async {
    final List<String> filePaths = List<String>.empty(growable: true);
    for (final String path in files.keys) {
      if (subFolderPath.isEmpty || path.startsWith(subFolderPath)) {
        filePaths.add(path);
      }
    }
    return filePaths;
  }

  @override
  Future<void> deleteEverything() async {
    hiveStorage.clear();
    secureStorage.clear();
    files.clear();
  }
}
