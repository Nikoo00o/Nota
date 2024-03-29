import 'dart:io';

import 'package:server/core/config/sensitive_data.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/utils/file_utils.dart';

class ServerConfig extends SharedConfig {
  /// Used to encrypt the account password hashes before saving them to the disk.
  String get serverKey => SensitiveData.serverKey;

  /// On the server side, the host name would only ever be used for local testing, so it can be set to localhost
  @override
  String get serverHostname => "https://127.0.0.1";

  /// Absolute path to the folder from the working directory where the server stores keys and database files
  String get resourceFolderPath => FileUtils.getLocalFilePath("notaRes");

  /// Local path to server public key certificate
  String get certificatePath => "$resourceFolderPath${Platform.pathSeparator}certificate.pem";

  /// Local path to server rsa private key
  String get privateKeyPath => "$resourceFolderPath${Platform.pathSeparator}key.pem";

  /// Local path to server notes path
  String get noteFolder => "$resourceFolderPath${Platform.pathSeparator}notes";

  /// Local path to server log files
  String get logFolder => "$resourceFolderPath${Platform.pathSeparator}logs";

  /// The remaining life time of a token after which the token will get refreshed.
  ///
  /// So a token gets refreshed after the time: [sessionTokenMaxLifetime] - [sessionTokenRefreshAfterRemainingTime].
  ///
  /// Here on the server side the [sessionTokenRefreshAfterRemainingTime] is one minute higher, so that the token will get
  /// refreshed on the server side earlier before the client would have to make a new request!
  @override
  Duration get sessionTokenRefreshAfterRemainingTime =>
      super.sessionTokenRefreshAfterRemainingTime + const Duration(minutes: 1);

  /// The timer delay for which the account repository cleans up the old sessions periodically
  Duration get clearOldSessionsAfter => const Duration(hours: 2);
}
