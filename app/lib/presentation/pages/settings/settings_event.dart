import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class SettingsEvent extends PageEvent {
  const SettingsEvent();
}

class SettingsEventInitialise extends SettingsEvent {
  const SettingsEventInitialise();
}

class SettingsEventLogout extends SettingsEvent {
  const SettingsEventLogout();
}
