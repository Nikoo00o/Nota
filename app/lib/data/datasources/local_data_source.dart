import 'dart:convert';

import 'package:app/data/models/client_account_model.dart';
import 'package:hive/hive.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/string_utils.dart';
import 'package:shared/data/datasources/hive_box_configuration.dart';
import 'package:shared/data/datasources/shared_hive_data_source_mixin.dart';

abstract class LocalDataSource {
  /// The database identifier of the hive box that contains the stored values
  static const String HIVE_DATABASE = "HIVE_DATABASE";

  /// The identifier for the hive encryption key
  static const String HIVE_KEY = "HIVE_KEY";

  /// Must be called first in the main function to initialize hive to the [getApplicationDocumentsDirectory].
  Future<void> init();

  /// Returns the hive encryption key that is stored in the secure storage, or generates a new one and saves it
  Future<String> generateHiveKey() async {
    String? key = await read(key: HIVE_KEY, secure: true);
    if (key != null) {
      return key;
    } else {
      key = StringUtils.getRandomBytesAsBase64String(SharedConfig.keyBytes);
      await write(key: HIVE_KEY, value: key, secure: true);
      Logger.debug("created new hive key: $key");
      return key;
    }
  }

  /// Returns the currently stored [ClientAccountModel], or null if it was not found
  Future<ClientAccountModel?> loadAccount(String userName) async {
    final String? jsonString = await read(key: userName, secure: false);
    if (jsonString != null) {
      return ClientAccountModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    }
    return null;
  }

  /// Stores the current account
  Future<void> saveAccount(ClientAccountModel account) async {
    await write(key: account.userName, value: jsonEncode(account), secure: false);
  }

  /// Needs to be overridden in the subclasses.
  /// Writes a [value] that can be accessed with the [key].
  /// Calls [delete] if [value] is [null].
  ///
  /// Will write to the hive database if [secure] is false. Otherwise it will write to the secure storage!
  Future<void> write({required String key, required String? value, required bool secure});

  /// Needs to be overridden in the subclasses.
  /// Returns the String value for the [key], or null if the key was not found.
  ///
  /// Will write to the hive database if [secure] is false. Otherwise it will write to the secure storage!
  Future<String?> read({required String key, required bool secure});

  /// Needs to be overridden in the subclasses.
  /// Deletes the value for the [key].
  ///
  /// Will write to the hive database if [secure] is false. Otherwise it will write to the secure storage!
  Future<void> delete({required String key, required bool secure});
}
