import 'dart:typed_data';

import 'package:shared/core/utils/nullable.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/entities/shared_account.dart';

/// The client specific account class with additional properties
class ClientAccount extends SharedAccount {
  /// The data key of the user used to encrypt the note data.
  /// Is mutable and not used in comparison!
  Uint8List? _cachedDataKey;

  ClientAccount({
    required super.userName,
    required super.passwordHash,
    required super.sessionToken,
    required super.noteInfoList,
    required super.encryptedDataKey,
  }) : super();

  /// Uses the userPassword to decrypt the [encryptedDataKey] into the [_cachedDataKey]
  void decryptDataKey(String userPassword) {
    // todo: decrypt and set the cached key
  }

  /// Returns the data key of the user used for encrypting the note data.
  ///
  /// [decryptDataKey] must be called first on this entity so that the key is not null!
  Uint8List? get decryptedDataKey => _cachedDataKey;

  /// Clears the cached data key in memory and sets it to null
  void clearDecryptedDataKey() {
    if (_cachedDataKey == null) {
      return;
    }
    for (int i = 0; i < _cachedDataKey!.length; ++i) {
      _cachedDataKey![i] = 0;
    }
    _cachedDataKey = null;
  }

  /// Creates a copy of this entity and changes the members to the parameters if they are not null.
  ///
  /// For Nullable parameter:
  /// If the Nullable Object itself is null, then it will not be used. Otherwise it's value is used to override the previous
  /// value (with either null, or a concrete value)
  @override
  ClientAccount copyWith({
    String? newPasswordHash,
    Nullable<SessionToken>? newSessionToken,
    List<NoteInfo>? newNoteInfoList,
    String? newEncryptedDataKey,
    String? newCachedDataKey,
  }) {
    final ClientAccount account = ClientAccount(
      userName: userName,
      passwordHash: newPasswordHash ?? passwordHash,
      sessionToken: newSessionToken != null ? newSessionToken.value : sessionToken,
      noteInfoList: newNoteInfoList ?? noteInfoList,
      encryptedDataKey: newEncryptedDataKey ?? encryptedDataKey,
    );
    account._cachedDataKey = _cachedDataKey;
    return account;
  }
}
