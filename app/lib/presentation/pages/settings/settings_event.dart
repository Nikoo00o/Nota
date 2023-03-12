import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class SettingsEvent extends PageEvent {
  const SettingsEvent();
}

class SettingsEventInitialise extends SettingsEvent {
  const SettingsEventInitialise();
}

class DarkThemeChanged extends SettingsEvent {
  final bool isDarkTheme;

  const DarkThemeChanged({required this.isDarkTheme});
}

class LocaleChanged extends SettingsEvent {
  final int index;

  const LocaleChanged({required this.index});
}

class AutoLoginChanged extends SettingsEvent {
  final bool autoLogin;

  const AutoLoginChanged({required this.autoLogin});
}

class LockscreenTimeoutChanged extends SettingsEvent {
  final String timeoutInSeconds;

  const LockscreenTimeoutChanged({required this.timeoutInSeconds});
}
