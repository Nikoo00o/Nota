import 'package:app/core/config/app_config.dart';
import 'package:app/core/get_it.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/repositories/biometrics_repository.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/string_utils.dart';

class BiometricsRepositoryImpl extends BiometricsRepository {
  static const String CONFIG_BIOMETRICS = "CONFIG_BIOMETRICS";

  final LocalDataSource localDataSource;
  final AppConfig appConfig;
  final DialogService dialogService;
  final LocalAuthentication auth = LocalAuthentication();

  /// the user key encrypted with the biometrics key. null before the first login and also if biometrics is disabled
  String? _encryptedUserKey;

  BiometricsRepositoryImpl({
    required this.localDataSource,
    required this.appConfig,
    required this.dialogService,
  });

  @override
  Future<(bool, String)> authenticate() async {
    final bool active = await isBiometricsActive();
    if (active && hasKey) {
      try {
        // direct access to TranslationService is needed here, because app settings repository needs biometrics
        // repository and biometrics repository needs translation service and translation service needs app settings
        // repository
        final bool success = await auth.authenticate(
          localizedReason: getIt<TranslationService>().translate("page.login.biometrics"),
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
        );
        if (success) {
          Logger.debug("authenticated with biometrics");
          return (true, await SecurityUtilsExtension.decryptStringAsync(_encryptedUserKey!, await _getBiometricsKey()));
        }
      } on PlatformException catch (e) {
        Logger.warn("biometric authentication failed: $e");
      }
    } else {
      Logger.warn("tried to authenticate with biometrics, but it was not active, or the key was null");
    }
    return (false, "");
  }

  @override
  Future<void> cacheUserKey(String base64EncodedUserKey) async {
    final bool active = await isBiometricsActive();
    if (active) {
      _encryptedUserKey =
          await SecurityUtilsExtension.encryptStringAsync(base64EncodedUserKey, await _getBiometricsKey());
      Logger.debug("cached encrypted biometrics user key");
    }
  }

  /// also creates the key if it doesn't already exist. the key is base64 encoded
  Future<String> _getBiometricsKey() async {
    String? key = await localDataSource.getBiometricKey();
    if (key == null) {
      key = StringUtils.getRandomBytesAsBase64String(SharedConfig.keyBytes);
      await localDataSource.setBiometricKey(biometricKey: key);
      Logger.debug("created new biometrics key");
    }
    return key;
  }

  @override
  bool get hasKey => _encryptedUserKey != null;

  @override
  Future<bool> isBiometricsActive() async {
    final bool enabled = await isBiometricsEnabled();
    if (enabled == false) {
      return false;
    }
    final bool supported = await isBiometricsSupported();
    return supported;
  }

  @override
  Future<bool> isBiometricsSupported() async {
    final bool supported = await auth.canCheckBiometrics;
    final List<BiometricType> available = await auth.getAvailableBiometrics();
    return supported && available.isNotEmpty;
  }

  @override
  Future<void> enableBiometrics({required bool enabled}) async {
    await localDataSource.setConfigValue(configKey: CONFIG_BIOMETRICS, configValue: enabled);
    if (enabled) {
      if (await isBiometricsSupported()) {
        Logger.debug("enabled biometrics");
        dialogService.showInfoDialog(const ShowInfoDialog(descriptionKey: "page.settings.biometrics.enabled"));
      } else {
        Logger.debug("enabled biometrics, but not supported yet");
        dialogService.showInfoDialog(const ShowInfoDialog(descriptionKey: "page.settings.biometrics.device"));
      }
    } else {
      _encryptedUserKey = null;
      Logger.debug("cleared encrypted biometrics user key");
    }
  }

  @override
  Future<bool> isBiometricsEnabled() => localDataSource.getConfigValue(configKey: CONFIG_BIOMETRICS);
}
