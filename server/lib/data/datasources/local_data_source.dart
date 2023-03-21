import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/models/server_account_model.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/data/datasources/hive_box_configuration.dart';
import 'package:shared/data/datasources/shared_hive_data_source_mixin.dart';

abstract class LocalDataSource {
  /// The database identifier of the hive box that contains the accounts
  static const String ACCOUNT_DATABASE = "ACCOUNT_DATABASE";

  /// The database identifier of the hive box that contains general server config values, like the note counter
  static const String CONFIG_DATABASE = "CONFIG_DATABASE";

  static const String NOTE_COUNTER = "NOTE_COUNTER";

  /// Must be called first in the main function to initialize the [ServerConfig.resourceFolderPath] folder for the
  /// databases, etc
  Future<void> init();

  /// Returns the stored [ServerAccountModel], or null.
  /// Only the accessed accounts will be loaded into memory.
  ///
  Future<ServerAccountModel?> loadAccount(String username) async {
    final String? jsonString = await read(key: username, databaseKey: ACCOUNT_DATABASE);
    if (jsonString != null) {
      return ServerAccountModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    }
    return null;
  }

  /// Stores a new [ServerAccountModel]
  Future<void> saveAccount(ServerAccountModel account) async {
    await write(key: account.username, value: jsonEncode(account), databaseKey: ACCOUNT_DATABASE);
  }

  /// Returns a list of all stored account user names!
  Future<List<String>> getAllAccountUsernames() async {
    return readAllKeys(databaseKey: ACCOUNT_DATABASE);
  }

  /// Returns 0 if the note counter was not initialised yet
  Future<int> getNoteCounter() async {
    final String? data = await read(key: NOTE_COUNTER, databaseKey: CONFIG_DATABASE);
    return int.parse(data ?? "0");
  }

  Future<void> setNoteCounter(int noteCounter) async {
    await write(key: NOTE_COUNTER, value: noteCounter.toString(), databaseKey: CONFIG_DATABASE);
  }

  /// Needs to be overridden in the subclasses.
  /// Writes a [value] that can be accessed with the [key].
  /// Calls [delete] if [value] is [null].
  ///
  /// The [databaseKey] parameter is used to identify which data base stores the [key] [value] pair!
  Future<void> write({required String key, required String? value, required String databaseKey});

  /// Needs to be overridden in the subclasses.
  /// Returns the String value for the [key], or null if the key was not found.
  ///
  /// The [databaseKey] parameter is used to identify which data base stores the [key] [value] pair!
  Future<String?> read({required String key, required String databaseKey});

  /// Needs to be overridden in the subclasses.
  /// Deletes the value for the [key].
  ///
  /// The [databaseKey] parameter is used to identify which data base stores the [key] [value] pair!
  Future<void> delete({required String key, required String databaseKey});

  /// Returns all keys that are stored inside the specific [databaseKey]. Might be an empty list.
  Future<List<String>> readAllKeys({required String databaseKey});
}

class LocalDataSourceImpl extends LocalDataSource with SharedHiveDataSourceMixin {
  final ServerConfig serverConfig;

  LocalDataSourceImpl({required this.serverConfig});

  @override
  Future<void> init() async {
    FileUtils.createDirectory(serverConfig.resourceFolderPath);
    Hive.init(serverConfig.resourceFolderPath);
  }

  @override
  Map<String, HiveBoxConfiguration> getHiveDataBaseConfig() {
    return <String, HiveBoxConfiguration>{
      LocalDataSource.ACCOUNT_DATABASE:
          HiveBoxConfiguration(isLazy: true, name: "Accounts", encryptionKey: serverConfig.serverKey),
      LocalDataSource.CONFIG_DATABASE:
          HiveBoxConfiguration(isLazy: false, name: "Config", encryptionKey: serverConfig.serverKey),
    };
  }

  @override
  Future<void> write({required String key, required String? value, required String databaseKey}) async {
    await writeToHive(key: key, value: value, databaseKey: databaseKey);
    // todo: could add more storage options, like secure storage plugin as alternatives
  }

  @override
  Future<String?> read({required String key, required String databaseKey}) async {
    return readFromHive(key: key, databaseKey: databaseKey);
  }

  @override
  Future<void> delete({required String key, required String databaseKey}) async {
    return deleteFromHive(key: key, databaseKey: databaseKey);
  }

  @override
  Future<List<String>> readAllKeys({required String databaseKey}) async {
    return getKeysFromHiveDatabase(databaseKey: databaseKey);
  }
}
