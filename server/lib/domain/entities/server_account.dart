import 'package:shared/core/utils/nullable.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/entities/shared_account.dart';

/// The server specific account class with additional properties
class ServerAccount extends SharedAccount {
  ServerAccount({
    required super.userName,
    required super.passwordHash,
    required super.sessionToken,
    required super.noteInfoList,
    required super.encryptedDataKey,
  }) : super();

  /// Creates a copy of this entity and changes the members to the parameters if they are not null.
  ///
  /// For Nullable parameter:
  /// If the Nullable Object itself is null, then it will not be used. Otherwise it's value is used to override the previous
  /// value (with either null, or a concrete value)
  @override
  ServerAccount copyWith({
    String? newPasswordHash,
    Nullable<SessionToken>? newSessionToken,
    List<NoteInfo>? newNoteInfoList,
    String? newEncryptedDataKey,
  }) {
    return ServerAccount(
      userName: userName,
      passwordHash: newPasswordHash ?? passwordHash,
      sessionToken: newSessionToken != null ? newSessionToken.value : sessionToken,
      noteInfoList: newNoteInfoList ?? noteInfoList,
      encryptedDataKey: newEncryptedDataKey ?? encryptedDataKey,
    );
  }

  /// Returns the hashed [userName] to be used as the name for the notes database of this account
  String get noteFileName => SecurityUtils.hashString(userName);
}
