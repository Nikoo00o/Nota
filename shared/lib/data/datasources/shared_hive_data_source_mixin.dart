import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/utils/hive_aes_gcm_cipher.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/datasources/hive_box_configuration.dart';

/// You have to override the method [getHiveDataBaseConfig] and return your hive boxes (data bases) you want to use with
/// the database key that is used to access it and also the path and box type.
mixin SharedHiveDataSourceMixin {
  /// contains the hive boxes which are used with the [database] parameter
  Map<String, BoxBase<dynamic>>? _hiveDatabases;

  /// You have to override this method in the sub class and return your hive boxes (data bases) you want to use with
  /// the database key that is used to access it. The config contains the path and box type.
  Map<String, HiveBoxConfiguration> getHiveDataBaseConfig() => throw UnimplementedError();

  /// Loads the hive boxes [_hiveDatabases] by using the [getHiveDataBaseConfig]
  Future<void> _loadHiveDatabases() async {
    if (_hiveDatabases == null) {
      _hiveDatabases = <String, BoxBase<dynamic>>{};

      for (final MapEntry<String, HiveBoxConfiguration> config in getHiveDataBaseConfig().entries) {
        late final BoxBase<dynamic> hiveBox;
        late final HiveCipher? cipher;
        if (config.value.encryptionKey != null) {
          cipher = HiveAesGcmCipher(keyBytes: base64Decode(config.value.encryptionKey!));
        }

        if (config.value.isGeneratedHiveObject) {
          hiveBox = await Hive.openBox(config.value.name, encryptionCipher: cipher);
        } else if (config.value.isLazy) {
          hiveBox = await Hive.openLazyBox<String>(config.value.name, encryptionCipher: cipher);
        } else {
          hiveBox = await Hive.openBox<String>(config.value.name, encryptionCipher: cipher);
        }
        _hiveDatabases![config.key] = hiveBox;
      }
    }
  }

  BoxBase<T> _getHiveBox<T>(String databaseKey) {
    if (_hiveDatabases?.containsKey(databaseKey) == false) {
      Logger.error("Error loading data, hive box $databaseKey does not exist");
      throw const FileException(message: ErrorCodes.FILE_NOT_FOUND);
    }
    return _hiveDatabases![databaseKey] as BoxBase<T>;
  }

  /// Helper method to access the hive boxes
  /// Writes a [value] that can be accessed with the [key].
  /// Calls [deleteFromHive] if [value] is [null].
  ///
  /// The [databaseKey] key parameter is used to identify which data base stores the [key] [value] pair!
  ///
  /// A [databaseKey] Hive box will be opened the first time it is accessed!
  Future<void> writeToHive({required String key, required String? value, required String databaseKey}) async {
    if (value == null) {
      await deleteFromHive(key: key, databaseKey: databaseKey);
    } else {
      await _loadHiveDatabases();
      final BoxBase<String> hiveBox = _getHiveBox(databaseKey);
      await hiveBox.put(key, value);
    }
  }

  /// Helper method to access the hive boxes.
  /// Returns the String value for the [key], or null if the key was not found.
  ///
  /// The [databaseKey] key parameter is used to identify which data base stores the [key] [value] pair!
  ///
  /// A [databaseKey] Hive box will be opened the first time it is accessed!
  Future<String?> readFromHive({required String key, required String databaseKey}) async {
    await _loadHiveDatabases();
    final BoxBase<String> hiveBox = _getHiveBox(databaseKey);
    if (hiveBox is LazyBox<String>) {
      return hiveBox.get(key);
    } else if (hiveBox is Box<String>) {
      return hiveBox.get(key);
    }
    return null;
  }

  /// Helper method to access the hive boxes.
  /// Returns all keys that are stored inside the hive box [databaseKey].
  ///
  /// If there are no [key] [value] pairs stored in the hive box, then the list will be empty.
  Future<List<String>> getKeysFromHiveDatabase({required String databaseKey}) async {
    await _loadHiveDatabases();
    final BoxBase<String> hiveBox = _getHiveBox(databaseKey);
    if (hiveBox is LazyBox<String>) {
      return List<String>.from(hiveBox.keys.toList());
    } else if (hiveBox is Box<String>) {
      return List<String>.from(hiveBox.keys.toList());
    }
    return <String>[];
  }

  /// This is used to retrieve all generated hive objects from the hive box with the [databaseKey].
  ///
  /// Important: the database must have been registered with [HiveBoxConfiguration.isGeneratedHiveObject], otherwise this
  /// will return null!
  ///
  /// The returned objects have functions to save, or delete them from the storage!
  ///
  /// The generic template type [T] is used as the type of your hive object.
  ///
  /// The [databaseKey] key parameter is used to identify which data base stores the object!
  ///
  /// A [databaseKey] Hive box will be opened the first time it is accessed!
  Future<List<T>> loadHiveObjects<T>({required String databaseKey}) async {
    await _loadHiveDatabases();
    final BoxBase<dynamic> hiveBox = _getHiveBox(databaseKey);
    if (hiveBox is Box<dynamic>) {
      return List<T>.from(hiveBox.values.toList());
    }
    return <T>[];
  }

  /// This adds a new generated hive object to the hive box with the [databaseKey]
  ///
  /// Important: the database must have been registered with [HiveBoxConfiguration.isGeneratedHiveObject]
  ///
  /// For access to the objects, you can use [loadHiveObjects].
  ///
  /// The [databaseKey] key parameter is used to identify which data base stores the object!
  ///
  /// A [databaseKey] Hive box will be opened the first time it is accessed!
  Future<void> addHiveObject({required dynamic object, required String databaseKey}) async {
    await _loadHiveDatabases();
    final BoxBase<dynamic> hiveBox = _getHiveBox(databaseKey);
    if (hiveBox is Box<dynamic>) {
      await hiveBox.add(object);
    }
  }

  /// Helper method to access the hive boxes.
  /// Deletes the value for the [key].
  ///
  /// The [databaseKey] key parameter is used to identify which data base stores the [key] [value] pair!
  ///
  /// A [databaseKey] Hive box will be opened the first time it is accessed!
  Future<void> deleteFromHive({required String key, required String databaseKey}) async {
    await _loadHiveDatabases();
    final BoxBase<String> hiveBox = _getHiveBox(databaseKey);
    await hiveBox.delete(key);
  }

  /// Deletes the hive box with the [databaseKey].
  Future<void> deleteHiveDatabase({required String databaseKey}) async {
    await _loadHiveDatabases();
    final BoxBase<String> hiveBox = _getHiveBox(databaseKey);
    await hiveBox.close();
    await hiveBox.deleteFromDisk();
  }

  /// Deletes all hive boxes
  Future<void> deleteAllHiveDatabases() async {
    await _loadHiveDatabases();
    for (final BoxBase<dynamic> hiveBox in _hiveDatabases!.values) {
      await hiveBox.close();
      await hiveBox.deleteFromDisk();
    }
    _hiveDatabases = null;
  }
}
