import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';

/// controls everything related to biometrics (the stored config option and the cached key)
abstract class BiometricsRepository {


  /// authenticates with biometrics and returns a bool if biometric login was successful and the decrypted base64
  /// encoded user key.
  ///
  /// First checks [isBiometricsActive] and [hasKey]
  Future<(bool, String)> authenticate();

  /// this is called by [LoginToAccount] and only caches the user key encrypted with the  biometrics key if biometric
  /// is supported and enabled!
  Future<void> cacheUserKey(String base64EncodedUserKey);

  /// returns if the [_encryptedUserKey] was set by the first login and is not null
  bool get hasKey;

  /// returns if [isBiometricsEnabled] and [isBiometricsSupported] are true
  Future<bool> isBiometricsActive();

  /// if the device supports biometrics and has biometrics enrolled
  Future<bool> isBiometricsSupported();

  /// changes biometrics to on/off. it will also be turned off inside of [LogoutOfAccount] by calling
  /// [AppSettingsRepository.resetAccountBoundSettings]. This  also clears the encrypted user key
  Future<void> enableBiometrics({required bool enabled});

  /// if biometric login is activated. (will be used instead of a password for every protected request except the
  /// first login after starting the app)
  Future<bool> isBiometricsEnabled();
}
