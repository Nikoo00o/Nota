import 'package:app/presentation/widgets/base_pages/page_state.dart';

class SettingsState extends PageState {
  const SettingsState([super.properties = const <String, Object?>{}]);
}

class SettingsStateInitialised extends SettingsState {
  final bool isDarkTheme;
  final int localeIndex;
  final List<String> localeOptions;

  SettingsStateInitialised({
    required this.isDarkTheme,
    required this.localeIndex,
    required this.localeOptions,
  }) : super(<String, Object?>{
          "isDarkTheme": isDarkTheme,
          "localeIndex": localeIndex,
          "localeOptions": localeOptions,
        });
}
