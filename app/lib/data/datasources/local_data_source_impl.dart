import 'dart:io';
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
  Future<String> getNoteFilePath(int noteId) async {
    final Directory documents = await getApplicationDocumentsDirectory();
    return "${documents.path}${Platform.pathSeparator}${appConfig.noteFolder}${Platform.pathSeparator}$noteId.note";
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
  Future<void> writeFile({required String filePath, required List<int> bytes}) async {
    return FileUtils.writeFileAsBytes(filePath, bytes);
  }

  @override
  Future<Uint8List?> readFile({required String filePath}) async {
    return FileUtils.readFileAsBytes(filePath);
  }

  @override
  Future<bool> deleteFile({required String filePath}) async {
    return FileUtils.deleteFileAsync(filePath);
  }
}
