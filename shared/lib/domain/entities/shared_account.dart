import 'package:shared/domain/entities/entity.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';

/// The base shared account class used in both server and client
class SharedAccount extends Entity {
  /// Used as identifier for accounts
  final String userName;

  /// Base64 encoded hash of the user password
  final String passwordHash;

  /// Can be null if not yet logged in, or if it expired
  final SessionToken? sessionToken;

  /// The base64 encoded data key of the user encrypted with the user key and used to encrypt the note data
  final String encryptedDataKey;

  /// The list of the information for each note from that account.
  ///
  /// Important: you should not directly modify the list if you want your modification to affect equality, because the
  /// list equality is compared by reference! Use a copyWith method in this case!
  final List<NoteInfo> noteInfoList;

  SharedAccount({
    required this.userName,
    required this.passwordHash,
    required this.sessionToken,
    required this.encryptedDataKey,
    required this.noteInfoList,
    Map<String, dynamic> additionalProperties = const <String, dynamic>{},
  }) : super(<String, dynamic>{
          "userName": userName,
          "passwordHash": passwordHash,
          "sessionToken": sessionToken,
          "encryptedDataKey": encryptedDataKey,
          "noteInfoList": noteInfoList,
          ...additionalProperties
        });

  /// Returns if this account contains the specific session token.
  /// Does not return if the Session token is valid, or not!!!
  bool containsSessionToken(String sessionToken) => sessionToken == (this.sessionToken?.token ?? "");

  /// Returns if the session token of this account is still valid for [additionalTime]
  bool isSessionTokenValidFor(Duration additionalTime) => sessionToken?.isValidFor(additionalTime) ?? false;

  /// Returns if the session token of this account is still valid for the next millisecond
  bool isSessionTokenStillValid() => sessionToken?.isStillValid() ?? false;
}
