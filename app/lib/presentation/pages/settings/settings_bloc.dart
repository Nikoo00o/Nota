import 'dart:ui';

import 'package:app/core/constants/locales.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/presentation/pages/settings/settings_event.dart';
import 'package:app/presentation/pages/settings/settings_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsBloc extends PageBloc<SettingsEvent, SettingsState> {
  final AppSettingsRepository appSettingsRepository;

  SettingsBloc({
    required this.appSettingsRepository,
  }) : super(initialState: const SettingsState());

  @override
  void registerEventHandlers() {
    on<SettingsEventInitialise>(_handleInitialise);
    on<DarkThemeChanged>(_handleDarkThemeChange);
    on<LocaleChanged>(_handleLocaleSelected);
  }

  Future<void> _handleInitialise(SettingsEventInitialise event, Emitter<SettingsState> emit) async {
    emit(await _buildState());
  }

  Future<void> _handleDarkThemeChange(DarkThemeChanged event, Emitter<SettingsState> emit) async {
    await appSettingsRepository.setDarkTheme(useDarkTheme: event.isDarkTheme);
    emit(await _buildState());
  }

  Future<void> _handleLocaleSelected(LocaleChanged event, Emitter<SettingsState> emit) async {
    Locale? newLocale;
    if (event.index < Locales.supportedLocales.length) {
      newLocale = Locales.supportedLocales[event.index];
    }
    await appSettingsRepository.setLocale(newLocale);
    emit(await _buildState());
  }

  Future<SettingsState> _buildState() async {
    return SettingsStateInitialized(
      isDarkTheme: await appSettingsRepository.isDarkTheme(),
      localeIndex: await _getLocaleIndex(),
      localeOptions: Locales.localeTranslationKeys.map((String key) => translate(key)).toList(),
    );
  }

  Future<int> _getLocaleIndex() async {
    int localeIndex = Locales.supportedLocales.length;
    final Locale? storedLocale = await appSettingsRepository.getStoredLocale();
    for (int i = 0; i < Locales.supportedLocales.length; ++i) {
      if (Locales.supportedLocales[i] == storedLocale) {
        localeIndex = i;
        break;
      }
    }
    return localeIndex;
  }
}
