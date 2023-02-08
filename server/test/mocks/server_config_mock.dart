import 'package:server/core/config/server_config.dart';

class ServerConfigMock extends ServerConfig {
  /// Used to mock the server port so that different test files can be run at the same time
  int? serverPortOverride;

  /// Used to mock the server token max lifetime for testing
  Duration? sessionTokenMaxLifetimeOverride;

  /// Used to mock the server token remaining refresh lifetime for testing
  Duration? sessionTokenRefreshAfterRemainingTimeOverride;

  /// Used to mock the servers periodic session cleanup
  Duration? clearOldSessionsAfterOverride;

  ServerConfigMock({this.serverPortOverride});

  @override
  int get serverPort => serverPortOverride ?? super.serverPort;

  @override
  Duration get sessionTokenMaxLifetime => sessionTokenMaxLifetimeOverride ?? super.sessionTokenMaxLifetime;

  @override
  Duration get sessionTokenRefreshAfterRemainingTime =>
      sessionTokenRefreshAfterRemainingTimeOverride ?? super.sessionTokenRefreshAfterRemainingTime;

  @override
  Duration get clearOldSessionsAfter => clearOldSessionsAfterOverride ?? super.clearOldSessionsAfter;
}
