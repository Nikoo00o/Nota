import 'dart:typed_data';

import 'package:shared/core/utils/list_utils.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/shared_account.dart';

/// The client specific account class with additional properties
class ClientAccount extends SharedAccount {
  /// The cached data key of the user used to encrypt the note data.
  ///
  /// This might be null at first.
  /// It's only set later when decrypting the [encryptedDataKey], or it is loaded from the storage depending on
  /// [storeDecryptedDataKey]!
  Uint8List? decryptedDataKey;

  /// This bool is set when changing the auto login config option to control if the [decryptedDataKey] should be included in
  /// the [toJson] method of the model and be written to the storage, or not depending on the config value.
  bool storeDecryptedDataKey;

  /// This is set during the login use case.
  /// [true] if the account needs to be logged in with a new login request with username+password on the login page, or
  /// [false] if the login page should only display the password field and the login should only be done locally.
  ///
  /// The purpose of this is to keep the accounts note data even if the account is logged out.
  bool needsServerSideLogin;

  ClientAccount({
    required super.userName,
    required super.passwordHash,
    required super.sessionToken,
    required super.noteInfoList,
    required super.encryptedDataKey,
    required this.decryptedDataKey,
    required this.storeDecryptedDataKey,
    required this.needsServerSideLogin,
  });

  /// Only sets username and password hash.
  /// [storeDecryptedDataKey] is false and [needsServerSideLogin] is true!
  factory ClientAccount.defaultValues({
    required String userName,
    required String passwordHash,
  }) {
    return ClientAccount(
      userName: userName,
      passwordHash: passwordHash,
      sessionToken: null,
      noteInfoList: <NoteInfo>[],
      encryptedDataKey: "",
      decryptedDataKey: null,
      storeDecryptedDataKey: false,
      needsServerSideLogin: true,
    );
  }

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

  @override
  Map<String, Object?> getProperties() {
    return super.getProperties()
      ..addAll(<String, Object?>{
        "decryptedDataKey": isLoggedIn ? "Not empty" : "Empty",
        "storeDecryptedDataKey": storeDecryptedDataKey,
        "needsServerSideLogin": needsServerSideLogin,
      });
  }

  @override

  /// Does not compare runtime type, because the comparison should also return true if its compared to the model
  bool operator ==(dynamic other) {
    return super == other &&
        other is ClientAccount &&
        ListUtils.equals(decryptedDataKey, other.decryptedDataKey) &&
        storeDecryptedDataKey == other.storeDecryptedDataKey &&
        needsServerSideLogin == other.needsServerSideLogin;
  }

  @override
  int get hashCode =>
      Object.hash(super.hashCode, decryptedDataKey?.hashCode, storeDecryptedDataKey.hashCode, needsServerSideLogin.hashCode);

  /// Returns if the account is completely logged in and ready to decrypt/encrypt notes by checking the [decryptedDataKey].
  /// This decides if the app shows the login page, or not!
  bool get isLoggedIn => decryptedDataKey?.isNotEmpty ?? false;

}
