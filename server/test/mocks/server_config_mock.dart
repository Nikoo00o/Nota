import 'package:server/core/config/server_config.dart';

class ServerConfigMock extends ServerConfig {
  /// Used to mock the server port so that different test files can be run at the same time
  int? serverPortOverride;

  /// Used for the test data folder which should be used instead of notaRes for the tests and each test should have its
  /// own folder in there
  String? resourceFolderPathOverride;

  /// Used to mock the server token max lifetime for testing
  Duration? sessionTokenMaxLifetimeOverride;

  /// Used to mock the server token remaining refresh lifetime for testing
  Duration? sessionTokenRefreshAfterRemainingTimeOverride;

  ServerConfigMock({this.serverPortOverride});

  @override
  int get serverPort => serverPortOverride ?? super.serverPort;

  @override
  String get resourceFolderPath => resourceFolderPathOverride ?? super.resourceFolderPath;

  @override
  Duration get sessionTokenMaxLifetime => sessionTokenMaxLifetimeOverride ?? super.sessionTokenMaxLifetime;

  @override
  Duration get sessionTokenRefreshAfterRemainingTime =>
      sessionTokenRefreshAfterRemainingTimeOverride ?? super.sessionTokenRefreshAfterRemainingTime;
}
