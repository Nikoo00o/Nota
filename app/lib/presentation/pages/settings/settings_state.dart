import 'package:app/presentation/widgets/base_pages/page_state.dart';

base class SettingsState extends PageState {
  const SettingsState([super.properties = const <String, Object?>{}]);
}

final class SettingsStateInitialised extends SettingsState {
  final bool isDarkTheme;
  final int localeIndex;
  final List<String> localeOptions;
  final bool autoLogin;
  final String lockscreenTimeoutInSeconds;
  final bool autoSave;
  final bool autoServerSync;
  final bool biometrics;

  SettingsStateInitialised({
    required this.isDarkTheme,
    required this.localeIndex,
    required this.localeOptions,
    required this.autoLogin,
    required this.lockscreenTimeoutInSeconds,
    required this.autoSave,
    required this.autoServerSync,
    required this.biometrics,
  }) : super(<String, Object?>{
          "isDarkTheme": isDarkTheme,
          "localeIndex": localeIndex,
          "localeOptions": localeOptions,
          "autoLogin": autoLogin,
          "lockscreenTimeoutInSeconds": lockscreenTimeoutInSeconds,
          "autoSave": autoSave,
          "autoServerSync": autoServerSync,
          "biometrics": biometrics,
        });
}
