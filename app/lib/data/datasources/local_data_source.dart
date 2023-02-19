import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:app/data/models/client_account_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/string_utils.dart';

/// Always call [init] first before using any other method!
abstract class LocalDataSource {
  /// The database identifier of the hive box that contains the stored values
  static const String HIVE_DATABASE = "HIVE_DATABASE";

  /// The identifier for the hive encryption key
  static const String HIVE_KEY = "HIVE_KEY";

  static const String ACCOUNT = "ACCOUNT";

  static const String LOCALE = "LOCALE";

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

  /// Returns the currently stored [ClientAccountModel] decrypted with the hive key, or null if it was not found
  Future<ClientAccountModel?> loadAccount() async {
    final String? jsonString = await read(key: ACCOUNT, secure: false);
    if (jsonString != null) {
      return ClientAccountModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    }
    return null;
  }

  /// Stores the current account and encrypts it with the hive key
  Future<void> saveAccount(ClientAccountModel account) async {
    await write(key: ACCOUNT, value: jsonEncode(account), secure: false);
  }

  Future<Locale?> getLocale() async {
    final String? languageCode = await read(key: LOCALE, secure: false);
    if (languageCode == null) {
      return null;
    }
    return Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    await write(key: LOCALE, value: locale.languageCode, secure: false);
  }

  /// Returns the content of the note which is encrypted with the users data key.
  ///
  /// The Note will be stored at "[getApplicationDocumentsDirectory()] / [appConfig.noteFolder] / [noteId] .note"
  ///
  /// So for example on android /data/user/0/com.nota.nota_app/app_flutter/notes/10.note
  ///
  /// If the note could not be found, this will throw a [FileException] with [ErrorCodes.FILE_NOT_FOUND]!
  Future<Uint8List> loadEncryptedNoteBytes(int noteId) async {
    final String filePath = await getNoteFilePath(noteId);
    final Uint8List? encryptedBytes = await readFile(filePath: filePath);
    if (encryptedBytes == null) {
      throw const FileException(message: ErrorCodes.FILE_NOT_FOUND);
    }
    return encryptedBytes;
  }

  /// Stores the content of the note which is encrypted with the users data key.
  ///
  /// The Note will be stored at "[getApplicationDocumentsDirectory()] / [appConfig.noteFolder] / [noteId] .note"
  ///
  /// So for example on android /data/user/0/com.nota.nota_app/app_flutter/notes/10.note
  Future<void> saveEncryptedNoteBytes(int noteId, List<int> encryptedBytes) async {
    final String filePath = await getNoteFilePath(noteId);
    await writeFile(filePath: filePath, bytes: encryptedBytes);
  }

  /// Returns the filePath to a specific note.
  ///
  /// The Note will be stored at "[getApplicationDocumentsDirectory()] / [appConfig.noteFolder] / [noteId] .note"
  ///
  /// So for example on android /data/user/0/com.nota.nota_app/app_flutter/notes/10.note
  Future<String> getNoteFilePath(int noteId);

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

  /// Creates all parent folders and writes the [bytes] to the specified [filePath]
  Future<void> writeFile({required String filePath, required List<int> bytes});

  /// Returns the bytes of the file at [filePath].
  ///
  /// Returns null if the [filePath] was not found
  Future<Uint8List?> readFile({required String filePath});

  /// Returns if the file at [filePath] existed and if it was deleted, or not.
  Future<bool> deleteFile({required String filePath});
}
