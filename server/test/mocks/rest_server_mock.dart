import 'dart:async';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/core/network/rest_server.dart';

/// Used to override the default authentication callback if needed
class RestServerMock extends RestServer {
  /// Used to override the default authentication callback if its not null
  FutureOr<ServerAccount?> Function(String sessionToken)? authenticationCallbackOverride;

  @override
  Future<ServerAccount?> getAuthenticatedAccount(String sessionToken) async {
    if (authenticationCallbackOverride != null) {
      return authenticationCallbackOverride!.call(sessionToken);
    } else {
      return super.getAuthenticatedAccount(sessionToken);
    }
  }
}
