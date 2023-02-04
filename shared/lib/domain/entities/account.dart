import 'package:shared/core/utils/nullable.dart';
import 'package:shared/domain/entities/entity.dart';
import 'package:shared/domain/entities/session_token.dart';

/// The base shared account class used in both server and client
class Account extends Entity {
  final String userName;
  final String passwordHash;
  final SessionToken? sessionToken;

  Account({required this.userName, required this.passwordHash, required this.sessionToken}) : super(<String, dynamic>{});

  /// Creates a copy of this account and changes the members to the parameters if they are not null.
  ///
  /// For Nullable parameter:
  /// If the Nullable Object itself is null, then it will not be used. Otherwise it's value is used to override the previous
  /// value (with either null, or a concrete value)
  @override
  Account copyWith({String? newPasswordHash, Nullable<SessionToken>? newSessionToken}) {
    return Account(
      userName: userName,
      passwordHash: newPasswordHash ?? passwordHash,
      sessionToken: newSessionToken != null ? newSessionToken.value : sessionToken,
    );
  }
}
