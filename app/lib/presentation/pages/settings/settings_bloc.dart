import 'dart:ui';

import 'package:app/core/constants/locales.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/usecases/account/change/change_auto_login.dart';
import 'package:app/domain/usecases/account/get_auto_login.dart';
import 'package:app/presentation/main/app/app_bloc.dart';
import 'package:app/presentation/main/app/app_event.dart';
import 'package:app/presentation/pages/settings/settings_event.dart';
import 'package:app/presentation/pages/settings/settings_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/usecases/usecase.dart';

class SettingsBloc extends PageBloc<SettingsEvent, SettingsState> {
  final AppSettingsRepository appSettingsRepository;
  final AppBloc appBloc;
  final GetAutoLogin getAutoLogin;
  final ChangeAutoLogin changeAutoLogin;

  SettingsBloc({
    required this.appSettingsRepository,
    required this.appBloc,
    required this.getAutoLogin,
    required this.changeAutoLogin,
  }) : super(initialState: const SettingsState());

  @override
  void registerEventHandlers() {
    on<SettingsEventInitialise>(_handleInitialise);
    on<DarkThemeChanged>(_handleDarkThemeChange);
    on<LocaleChanged>(_handleLocaleSelected);
    on<AutoLoginChanged>(_handleAutoLoginChanged);
    on<LockscreenTimeoutChanged>(_lockscreenTimeoutChanged);
  }

  Future<void> _handleInitialise(SettingsEventInitialise event, Emitter<SettingsState> emit) async {
    emit(await _buildState());
  }

  Future<void> _handleDarkThemeChange(DarkThemeChanged event, Emitter<SettingsState> emit) async {
    await appSettingsRepository.setDarkTheme(useDarkTheme: event.isDarkTheme);
    appBloc.add(UpdateTheme(useDarkTheme: event.isDarkTheme)); // update the app and force a rebuild
    emit(await _buildState());
  }

  Future<void> _handleLocaleSelected(LocaleChanged event, Emitter<SettingsState> emit) async {
    Locale? newLocale; // null if system locale should be used
    if (event.index < Locales.supportedLocales.length) {
      newLocale = Locales.supportedLocales[event.index];
    }
    await appSettingsRepository.setLocale(newLocale);
    appBloc.add(UpdateLocale(await appSettingsRepository.getCurrentLocale())); // update the app and force a rebuild
    emit(await _buildState());
  }

  Future<void> _handleAutoLoginChanged(AutoLoginChanged event, Emitter<SettingsState> emit) async {
    await changeAutoLogin.call(ChangeAutoLoginParams(autoLogin: event.autoLogin));
    emit(await _buildState());
  }

  Future<void> _lockscreenTimeoutChanged(LockscreenTimeoutChanged event, Emitter<SettingsState> emit) async {
    await appSettingsRepository.setLockscreenTimeout(duration: Duration(seconds: int.parse(event.timeoutInSeconds)));
    emit(await _buildState());
  }

  Future<SettingsState> _buildState() async {
    final Duration timeout = await appSettingsRepository.getLockscreenTimeout();
    return SettingsStateInitialised(
      isDarkTheme: await appSettingsRepository.isDarkTheme(),
      localeIndex: await _getLocaleIndex(),
      localeOptions: Locales.localeTranslationKeys,
      autoLogin: await getAutoLogin.call(const NoParams()),
      lockscreenTimeoutInSeconds: timeout.inSeconds.toString(),
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
