import 'package:shared/domain/entities/entity.dart';

/// The session token for the authentication of accounts
class SessionToken extends Entity {
  final String token;
  final DateTime validTo;

  SessionToken({required this.token, required this.validTo})
      : super(<String, dynamic>{
          "token": token,
          "validTo": validTo,
        });
}
