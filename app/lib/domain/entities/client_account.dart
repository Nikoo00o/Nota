import 'dart:typed_data';

import 'package:shared/core/utils/nullable.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/entities/shared_account.dart';

/// The client specific account class with additional properties
class ClientAccount extends SharedAccount {
  /// The cached data key of the user used to encrypt the note data.
  ///
  /// This is not used in comparison and might be null at first.
  /// It's only set later when decrypting the [encryptedDataKey], or it is loaded from the storage depending on
  /// [storeDecryptedDataKey]!
  Uint8List? decryptedDataKey;

  /// This bool is set to control if the [decryptedDataKey] should be included in the [toJson] method of the model and be
  /// written to the storage, or not depending on the config value.
  bool storeDecryptedDataKey;

  ClientAccount({
    required super.userName,
    required super.passwordHash,
    required super.sessionToken,
    required super.noteInfoList,
    required super.encryptedDataKey,
    required this.decryptedDataKey,
    required this.storeDecryptedDataKey,
  }) : super();

  /// Clears the cached data key in memory and sets it to null
  void clearDecryptedDataKey() {
    if (decryptedDataKey == null) {
      return;
    }
    for (int i = 0; i < decryptedDataKey!.length; ++i) {
      decryptedDataKey![i] = 0;
    }
    decryptedDataKey = null;
  }
}
