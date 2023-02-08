import 'dart:async';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/core/network/rest_server.dart';

/// Used to override the default authentication callback if needed
class RestServerMock extends RestServer {
  /// Used to override the default authentication callback if its not null
  FutureOr<ServerAccount?> Function(String sessionToken)? authenticationCallbackOverride;

  @override
  FutureOr<ServerAccount?> Function(String sessionToken)? get authenticationCallback =>
      authenticationCallbackOverride ?? super.authenticationCallback;
}
