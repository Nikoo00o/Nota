import 'package:shared/core/config/sensitive_data.dart';

class SharedConfig {
  /// This is used as a part of [getServerUrl].
  int get serverPort => 8191;

  /// The https domain of the server. Must be a valid url encoded domain that starts with "https://".
  /// This is used as a part of [getServerUrl].
  String get serverHostname => SensitiveData.serverHostname;

  /// Used when creating the password hash from the password (which will be send to the server)
  String get passwordHashSalt => SensitiveData.passwordHashSalt;

  /// Used when creating the user key from the password (which will only be stored inside the app)
  String get userKeySalt => SensitiveData.userKeySalt;

  /// Used when creating a new account to prevent account creation from outside of the app.
  String get createAccountToken => SensitiveData.createAccountToken;

  /// If the Client should accept self signed certificates from the server that are not trusted by any root CA
  bool get acceptSelfSignedCertificates => true;

  /// Returns the combination of: "[serverHostname] : [serverPort]" to return the complete server url!
  String getServerUrl() {
    String url = serverHostname;
    if (url.endsWith("/")) {
      url = url.substring(0, url.length - 1);
    }
    return "$url:$serverPort";
  }
}
