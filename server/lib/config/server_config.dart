import 'package:server/config/sensitive_data.dart';
import 'package:shared/core/config/shared_config.dart';

class ServerConfig extends SharedConfig {
  /// Used to encrypt the account password hashes before saving them to the disk.
  String get serverKey => SensitiveData.serverKey;

  /// On the server side, the host name would only ever be used for local testing, so it can be set to localhost
  @override
  String get serverHostname => "https://127.0.0.1";
}
