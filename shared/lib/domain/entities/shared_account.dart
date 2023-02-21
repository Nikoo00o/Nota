import 'package:shared/core/utils/list_utils.dart';
import 'package:shared/core/utils/string_utils.dart';
import 'package:shared/domain/entities/entity.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';

/// The base shared account class used in both server and client.
///
/// This is a mutable entity.
///
/// Some fields of this entity can be modified and are not final.
class SharedAccount {
  /// Used as identifier for accounts
  String userName;

  /// Base64 encoded hash of the user password
  String passwordHash;

  /// Can be null if not yet logged in, or if it expired
  SessionToken? sessionToken;

  /// The base64 encoded data key of the user encrypted with the user key and used to encrypt the note data
  String encryptedDataKey;

  /// The list of the information for each note from that account.
  ///
  /// Important: you should not directly modify the list if you want your modification to affect equality, because the
  /// list equality is compared by reference! Better copy the list then
  List<NoteInfo> noteInfoList;

  SharedAccount({
    required this.userName,
    required this.passwordHash,
    required this.sessionToken,
    required this.encryptedDataKey,
    required this.noteInfoList,
  });

  @override

  /// Does not compare runtime type, because the comparison should also return true if its compared to the model
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! SharedAccount) {
      return false;
    }
    return userName == other.userName &&
        passwordHash == other.passwordHash &&
        sessionToken == other.sessionToken &&
        encryptedDataKey == other.encryptedDataKey &&
        ListUtils.equals(noteInfoList, other.noteInfoList);
  }

  @override
  int get hashCode => Object.hash(
      userName.hashCode, passwordHash.hashCode, sessionToken.hashCode, encryptedDataKey.hashCode, noteInfoList.hashCode);

  Map<String, Object?> getProperties() {
    return <String, Object?>{
      "userName": userName,
      "passwordHash": passwordHash,
      "sessionToken": sessionToken,
      "encryptedDataKey": encryptedDataKey,
      "noteInfoList": noteInfoList,
    };
  }

  @override
  String toString() {
    return StringUtils.toStringPretty(this, getProperties());
  }

  /// Returns if this account contains the specific session token.
  /// Does not return if the Session token is valid, or not!!!
  bool containsSessionToken(String sessionToken) => sessionToken == (this.sessionToken?.token ?? "");

  /// Returns if the session token of this account is still valid for [additionalTime]
  bool isSessionTokenValidFor(Duration additionalTime) => sessionToken?.isValidFor(additionalTime) ?? false;

  /// Returns if the session token of this account is still valid for the next millisecond
  bool isSessionTokenStillValid() => sessionToken?.isStillValid() ?? false;
}
