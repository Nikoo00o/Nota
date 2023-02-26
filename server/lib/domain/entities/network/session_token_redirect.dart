import 'package:shared/domain/entities/entity.dart';
import 'package:shared/domain/entities/session_token.dart';

/// redirects requests with the old [from] token to the account with the new [to] token [SessionToken]
class SessionTokenRedirect extends Entity {
  /// The old session token from the account that is still valid for some time
  final SessionToken from;

  /// The new session token for the account which is the replacement
  final SessionToken to;

  SessionTokenRedirect({required this.from, required this.to})
      : super(<String, Object?>{
          "from": from,
          "to": to,
        });

  /// Returns if both session tokens are still valid for another millisecond
  bool isStillValid() => from.isStillValid() && to.isStillValid();
}
