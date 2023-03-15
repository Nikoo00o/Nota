import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:app/core/config/app_config.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/datasources/hive_box_configuration.dart';
import 'package:shared/data/datasources/shared_hive_data_source_mixin.dart';

class LocalDataSourceImpl extends LocalDataSource with SharedHiveDataSourceMixin {
  final FlutterSecureStorage secureStorage;
  final AppConfig appConfig;

  /// base 64 encoded hive encryption key
  String? _hiveKey;

  LocalDataSourceImpl({required this.secureStorage, required this.appConfig});

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _hiveKey = await generateHiveKey();
  }

  @override
  Map<String, HiveBoxConfiguration> getHiveDataBaseConfig() {
    assert(_hiveKey != null, "hive key must be set by calling init before");
    return <String, HiveBoxConfiguration>{
      LocalDataSource.HIVE_DATABASE: HiveBoxConfiguration(isLazy: false, name: "hive", encryptionKey: _hiveKey),
    };
  }

  @override
  Future<void> write({required String key, required String? value, required bool secure}) async {
    if (value == null) {
      return delete(key: key, secure: secure);
    }
    if (secure == false) {
      await writeToHive(key: key, value: value, databaseKey: LocalDataSource.HIVE_DATABASE);
    } else {
      await secureStorage.write(key: key, value: value);
    }
  }

  @override
  Future<String?> read({required String key, required bool secure}) async {
    if (secure == false) {
      return readFromHive(key: key, databaseKey: LocalDataSource.HIVE_DATABASE);
    } else {
      return secureStorage.read(key: key);
    }
  }

  @override
  Future<void> delete({required String key, required bool secure}) async {
    if (secure == false) {
      await deleteFromHive(key: key, databaseKey: LocalDataSource.HIVE_DATABASE);
    } else {
      await secureStorage.delete(key: key);
    }
  }

  @override
  Future<void> writeFile({required String localFilePath, required List<int> bytes}) async {
    return FileUtils.writeFileAsBytes(await _getAbsolutePath(localFilePath), bytes);
  }

  @override
  Future<Uint8List?> readFile({required String localFilePath}) async {
    return FileUtils.readFileAsBytes(await _getAbsolutePath(localFilePath));
  }

  @override
  Future<bool> deleteFile({required String localFilePath}) async {
    return FileUtils.deleteFileAsync(await _getAbsolutePath(localFilePath));
  }

  @override
  Future<bool> renameFile({required String oldLocalFilePath, required String newLocalFilePath}) async {
    final String oldPath = await _getAbsolutePath(oldLocalFilePath);
    if (await FileUtils.fileExistsAsync(oldPath) == false) {
      return false;
    }
    await FileUtils.moveFileAsync(oldPath, await _getAbsolutePath(newLocalFilePath));
    return true;
  }

  @override
  Future<List<String>> getFilePaths({required String subFolderPath}) async =>
      FileUtils.getFilesInDirectory(await _getAbsolutePath(subFolderPath));

  @override
  Future<void> deleteEverything() async {
    await deleteAllHiveDatabases();
    await secureStorage.deleteAll();
  }

  Future<String> _getAbsolutePath(String localFilePath) async {
    final Directory documents = await getApplicationDocumentsDirectory();
    if (localFilePath.isEmpty) {
      return documents.path;
    } else if (localFilePath.startsWith(documents.path)) {
      return localFilePath;
    } else {
      return "${documents.path}${Platform.pathSeparator}$localFilePath";
    }
  }
}
