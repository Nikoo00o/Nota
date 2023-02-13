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

  /// Returns the hashed [userName] to be used as the name for the notes database of this account
  String get noteFileName => SecurityUtils.hashString(userName);
}
