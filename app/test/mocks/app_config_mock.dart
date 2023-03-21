import 'package:app/core/config/app_config.dart';

class AppConfigMock extends AppConfig {
  /// Used to override the default config server port for the tests.
  int? serverPortOverride;

  /// Used to override the host name for the tests
  String? serverHostnameOverride;

  @override
  int get serverPort => serverPortOverride ?? super.serverPort;

  @override
  String get serverHostname => serverHostnameOverride ?? super.serverHostname;
}
