import 'package:shared/domain/entities/entity.dart';

/// The session token for the authentication of accounts
class SessionToken extends Entity {
  /// base64 encoded
  final String token;

  /// TimeStamp for when this token expires
  final DateTime validTo;

  SessionToken({required this.token, required this.validTo})
      : super(<String, Object?>{
          "token": token,
          "validTo": validTo,
        });

  /// Returns if the session token is still valid for [additionalTime]
  bool isValidFor(Duration additionalTime) => DateTime.now().add(additionalTime).isBefore(validTo) && token.isNotEmpty;

  /// Returns if the session token is still valid for the next millisecond
  bool isStillValid() => isValidFor(const Duration(milliseconds: 1));
}
