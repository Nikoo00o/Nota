import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class SettingsEvent extends PageEvent {
  const SettingsEvent();
}

class SettingsEventInitialise extends SettingsEvent {
  const SettingsEventInitialise();
}

class SettingsDarkThemeChanged extends SettingsEvent {
  final bool isDarkTheme;

  const SettingsDarkThemeChanged({required this.isDarkTheme});
}

class SettingsLocaleChanged extends SettingsEvent {
  final int index;

  const SettingsLocaleChanged({required this.index});
}

class SettingsAutoLoginChanged extends SettingsEvent {
  final bool autoLogin;

  const SettingsAutoLoginChanged({required this.autoLogin});
}

class SettingsLockscreenTimeoutChanged extends SettingsEvent {
  final String timeoutInSeconds;

  const SettingsLockscreenTimeoutChanged({required this.timeoutInSeconds});
}

class SettingsNavigatedToChangePasswordPage extends SettingsEvent {
  const SettingsNavigatedToChangePasswordPage();
}

class SettingsPasswordChanged extends SettingsEvent {
  final bool cancel;
  const SettingsPasswordChanged({required this.cancel});
}