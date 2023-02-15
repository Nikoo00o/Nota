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

}
