import 'package:app/presentation/widgets/base_pages/page_event.dart';

sealed class SettingsEvent extends PageEvent {
  const SettingsEvent();
}

final class SettingsEventInitialise extends SettingsEvent {
  const SettingsEventInitialise();
}

final class SettingsDarkThemeChanged extends SettingsEvent {
  final bool isDarkTheme;

  const SettingsDarkThemeChanged({required this.isDarkTheme});
}

final class SettingsLocaleChanged extends SettingsEvent {
  final int index;

  const SettingsLocaleChanged({required this.index});
}

final class SettingsAutoLoginChanged extends SettingsEvent {
  final bool autoLogin;

  const SettingsAutoLoginChanged({required this.autoLogin});
}

final class SettingsLockscreenTimeoutChanged extends SettingsEvent {
  final String timeoutInSeconds;

  const SettingsLockscreenTimeoutChanged({required this.timeoutInSeconds});
}

final class SettingsNavigatedToChangePasswordPage extends SettingsEvent {
  const SettingsNavigatedToChangePasswordPage();
}

final class SettingsPasswordChanged extends SettingsEvent {
  final bool cancel;
  const SettingsPasswordChanged({required this.cancel});
}

final class SettingsAutoSaveChanged extends SettingsEvent {
  final bool autoSave;

  const SettingsAutoSaveChanged({required this.autoSave});
}