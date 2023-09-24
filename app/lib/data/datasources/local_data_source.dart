import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:app/core/config/app_config.dart';
import 'package:app/data/models/client_account_model.dart';
import 'package:app/data/models/favourites_model.dart';
import 'package:app/domain/entities/favourites.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/log_message.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/string_utils.dart';
import 'package:shared/data/models/note_info_model.dart';
import 'package:shared/domain/entities/note_info.dart';

/// Always call [init] first before using any other method!
///
/// The local hive database is encrypted with a hive key that is stored in the secure storage.
///
/// All other data is stored inside of the local hive database.
abstract class LocalDataSource {
  /// The database identifier of the hive box that contains the stored key-value pairs with the json identifiers
  static const String HIVE_DATABASE = "HIVE_DATABASE";

  /// The database identifier of the hive box that contains the stored generated log entry objects
  static const String LOG_DATABASE = "LOG_DATABASE";

  /// The identifier for the hive encryption key
  static const String HIVE_KEY = "HIVE_KEY";

  static const String ACCOUNT = "ACCOUNT";

  static const String OLD_ACCOUNTS = "OLD_ACCOUNTS";

  static const String LOCALE = "LOCALE";

  static const String CLIENT_NOTE_COUNTER = "CLIENT_NOTE_COUNTER";

  static const String CONFIG_PREFIX = "CONFIG_PREFIX";

  static const String LOCK_SCREEN_TIMEOUT = "LOCK_SCREEN_TIMEOUT";

  static const String LOG_LEVEL = "LOG_LEVEL";

  static const String LAST_NOTE_TRANSFER_TIME = "LAST_NOTE_TRANSFER_TIME";

  static const String FAVOURITES = "FAVOURITES";

  static const String BIOMETRIC_KEY = "BIOMETRIC_KEY";

  /// Must be called first in the main function to initialize hive to the [AppConfig.baseFolder]
  /// of [getApplicationDocumentsDirectory]. This will also create the base folder if it does not exist yet!
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

  /// Returns the currently stored [ClientAccountModel] decrypted with the hive key, or null if it was not found
  Future<ClientAccountModel?> loadAccount() async {
    final String? jsonString = await read(key: ACCOUNT, secure: false);
    if (jsonString != null) {
      return ClientAccountModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    }
    return null;
  }

  /// Stores the current account and encrypts it with the hive key, or deletes the stored account if [account] is null.
  Future<void> saveAccount(ClientAccountModel? account) async {
    if (account == null) {
      await delete(key: ACCOUNT, secure: false);
    } else {
      await write(key: ACCOUNT, value: jsonEncode(account), secure: false);
    }
  }

  /// Returns the usernames matched to the note info lists of old logged in accounts, so that the notes don't get lost
  Future<Map<String, List<NoteInfo>>> getOldAccounts() async {
    final String? jsonString = await read(key: OLD_ACCOUNTS, secure: false);
    if (jsonString == null) {
      return <String, List<NoteInfo>>{};
    }
    final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
    return json.map((String username, dynamic value) {
      final List<dynamic> dynList = value as List<dynamic>;
      final List<NoteInfo> notes =
          dynList.map<NoteInfo>((dynamic map) => NoteInfoModel.fromJson(map as Map<String, dynamic>)).toList();
      return MapEntry<String, List<NoteInfo>>(username, notes);
    });
  }

  /// Stores the usernames matched to the note info lists of old logged in accounts, so that the notes don't get lost
  Future<void> saveOldAccounts(Map<String, List<NoteInfo>> oldAccounts) async {
    final Map<String, List<NoteInfoModel>> mapped = oldAccounts.map((String key, List<NoteInfo> value) =>
        MapEntry<String, List<NoteInfoModel>>(
            key, value.map((NoteInfo note) => NoteInfoModel.fromNoteInfo(note)).toList()));
    await write(key: OLD_ACCOUNTS, value: jsonEncode(mapped), secure: false);
  }

  Future<Locale?> getLocale() async {
    final String? languageCode = await read(key: LOCALE, secure: false);
    if (languageCode == null) {
      return null;
    }
    return Locale(languageCode);
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await delete(key: LOCALE, secure: false);
    } else {
      await write(key: LOCALE, value: locale.languageCode, secure: false);
    }
  }

  Future<int?> getClientNoteCounter() async {
    final String? value = await read(key: CLIENT_NOTE_COUNTER, secure: false);
    if (value == null) {
      return null;
    }
    return int.parse(value);
  }

  Future<void> setClientNoteCounter(int clientNoteCounter) async {
    await write(key: CLIENT_NOTE_COUNTER, value: clientNoteCounter.toString(), secure: false);
  }

  /// Returns the config toggle value with the [configKey].
  ///
  /// Per default this will return false.
  Future<bool> getConfigValue({required String configKey}) async {
    final String? value = await read(key: "${CONFIG_PREFIX}_$configKey", secure: false);
    if (value == null) {
      return false;
    }
    return value == "true";
  }

  /// This sets the value at the [configKey] to the [configValue] which can be retrieved with [getConfigValue].
  Future<void> setConfigValue({required String configKey, required bool configValue}) async {
    await write(key: "${CONFIG_PREFIX}_$configKey", value: configValue.toString(), secure: false);
  }

  Future<Duration?> getLockscreenTimeout() async {
    final String? value = await read(key: LOCK_SCREEN_TIMEOUT, secure: false);
    if (value == null) {
      return null;
    }
    return Duration(milliseconds: int.parse(value));
  }

  Future<void> setLockscreenTimeout({required Duration duration}) async {
    await write(key: LOCK_SCREEN_TIMEOUT, value: duration.inMilliseconds.toString(), secure: false);
  }

  Future<LogLevel?> getLogLevel() async {
    final String? value = await read(key: LOG_LEVEL, secure: false);
    if (value == null) {
      return null;
    }
    return LogLevel.fromString(value);
  }

  Future<void> setLogLevel({required LogLevel logLevel}) async {
    await write(key: LOG_LEVEL, value: logLevel.toString(), secure: false);
  }

  Future<void> addLog(LogMessage log);

  Future<List<LogMessage>> getLogs();

  Future<DateTime> getLastNoteTransferTime() async {
    final String? value = await read(key: LAST_NOTE_TRANSFER_TIME, secure: false);
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
  }

  Future<void> setLastNoteTransferTime({required DateTime timeStamp}) async {
    await write(key: LAST_NOTE_TRANSFER_TIME, value: timeStamp.millisecondsSinceEpoch.toString(), secure: false);
  }

  Future<Favourites> getFavourites() async {
    final String? value = await read(key: FAVOURITES, secure: false);
    if (value == null) {
      return Favourites(favourites: List<Favourite>.empty(growable: true));
    }
    return FavouritesModel.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> setFavourites({required FavouritesModel favourites}) async {
    await write(key: FAVOURITES, value: jsonEncode(favourites), secure: false);
  }

  /// saved in secure storage
  Future<String?> getBiometricKey() => read(key: BIOMETRIC_KEY, secure: true); // secure

  /// saved in secure storage
  Future<void> setBiometricKey({required String? biometricKey}) =>
      write(key: BIOMETRIC_KEY, value: biometricKey, secure: true); // secure

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

  /// Creates all parent folders and writes the [bytes] to the specified [getBasePath] / [localFilePath]
  ///
  /// The application documents directory will for example be: /data/user/0/com.Nikoo00o.nota.app/app_flutter/nota/
  Future<void> writeFile({required String localFilePath, required List<int> bytes});

  /// Returns the bytes of the file at [getBasePath] / [localFilePath].
  ///
  /// Returns null if the [getBasePath] / [localFilePath] was not found
  ///
  /// The application documents directory will for example be: /data/user/0/com.Nikoo00o.nota.app/app_flutter/nota/
  Future<Uint8List?> readFile({required String localFilePath});

  /// Returns if the file at [getBasePath] / [localFilePath] existed and if it was deleted, or not.
  ///
  /// The application documents directory will for example be: /data/user/0/com.Nikoo00o.nota.app/app_flutter/nota/
  Future<bool> deleteFile({required String localFilePath});

  /// Renames the file from [oldLocalFilePath] to [newLocalFilePath] and returns if the old file existed, or not.
  ///
  /// Both paths must be in the application documents directory!
  Future<bool> renameFile({required String oldLocalFilePath, required String newLocalFilePath});

  /// Returns a list of files with their full absolute file paths inside of the [subFolderPath] in relation to the
  /// applications documents directory.
  ///
  /// [subFolderPath] can also be empty and it can also point to a file inside of the target folder!
  Future<List<String>> getFilePaths({required String subFolderPath});

  /// Clears all key - value pairs and also all keys, etc. Afterwards [init] has to be called again!
  ///
  /// Also deletes all files!!!
  Future<void> deleteEverything();

  /// This returns the [getApplicationDocumentsDirectory] combined with the [AppConfig.baseFolder] as the folder where all
  /// files and folders of the app are stored!
  Future<String> getBasePath();
}
