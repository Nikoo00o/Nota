import 'dart:ui';

import 'package:app/core/constants/locales.dart';
import 'package:app/core/utils/input_validator.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/usecases/account/change/change_account_password.dart';
import 'package:app/domain/usecases/account/change/change_auto_login.dart';
import 'package:app/domain/usecases/account/get_auto_login.dart';
import 'package:app/presentation/main/app/app_bloc.dart';
import 'package:app/presentation/main/app/app_event.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/settings/settings_event.dart';
import 'package:app/presentation/pages/settings/settings_state.dart';
import 'package:app/presentation/pages/settings/widgets/change_password_page.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/usecases/usecase.dart';

class SettingsBloc extends PageBloc<SettingsEvent, SettingsState> {
  final AppSettingsRepository appSettingsRepository;
  final NavigationService navigationService;
  final DialogService dialogService;
  final ChangeAccountPassword changeAccountPassword;
  final AppBloc appBloc;
  final GetAutoLogin getAutoLogin;
  final ChangeAutoLogin changeAutoLogin;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();

  SettingsBloc({
    required this.appSettingsRepository,
    required this.navigationService,
    required this.dialogService,
    required this.changeAccountPassword,
    required this.appBloc,
    required this.getAutoLogin,
    required this.changeAutoLogin,
  }) : super(initialState: const SettingsState());

  @override
  void registerEventHandlers() {
    on<SettingsEventInitialise>(_handleInitialise);
    on<SettingsDarkThemeChanged>(_handleDarkThemeChange);
    on<SettingsLocaleChanged>(_handleLocaleSelected);
    on<SettingsAutoLoginChanged>(_handleAutoLoginChanged);
    on<SettingsLockscreenTimeoutChanged>(_handleLockscreenTimeoutChanged);
    on<SettingsNavigatedToChangePasswordPage>(_handleNavigatedToChangePasswordPage);
    on<SettingsPasswordChanged>(_handlePasswordChanged);
  }

  Future<void> _handleInitialise(SettingsEventInitialise event, Emitter<SettingsState> emit) async {
    emit(await _buildState());
  }

  Future<void> _handleDarkThemeChange(SettingsDarkThemeChanged event, Emitter<SettingsState> emit) async {
    await appSettingsRepository.setDarkTheme(useDarkTheme: event.isDarkTheme);
    appBloc.add(AppUpdateTheme(useDarkTheme: event.isDarkTheme)); // update the app and force a rebuild
    emit(await _buildState());
  }

  Future<void> _handleLocaleSelected(SettingsLocaleChanged event, Emitter<SettingsState> emit) async {
    Locale? newLocale; // null if system locale should be used
    if (event.index < Locales.supportedLocales.length) {
      newLocale = Locales.supportedLocales[event.index];
    }
    await appSettingsRepository.setLocale(newLocale);
    appBloc.add(AppUpdateLocale(await appSettingsRepository.getCurrentLocale())); // update the app and force a rebuild
    emit(await _buildState());
  }

  Future<void> _handleAutoLoginChanged(SettingsAutoLoginChanged event, Emitter<SettingsState> emit) async {
    await changeAutoLogin.call(ChangeAutoLoginParams(autoLogin: event.autoLogin));
    emit(await _buildState());
  }

  Future<void> _handleLockscreenTimeoutChanged(SettingsLockscreenTimeoutChanged event, Emitter<SettingsState> emit) async {
    await appSettingsRepository.setLockscreenTimeout(duration: Duration(seconds: int.parse(event.timeoutInSeconds)));
    emit(await _buildState());
  }

  Future<void> _handleNavigatedToChangePasswordPage(SettingsNavigatedToChangePasswordPage event, Emitter<SettingsState> emit) async {
    passwordController.clear(); // if the change password page is opened multiple times
    passwordConfirmController.clear();
    navigationService.pushPage(ChangePasswordPage(bloc: this));
    emit(await _buildState());
  }

  Future<void> _handlePasswordChanged(SettingsPasswordChanged event, Emitter<SettingsState> emit) async {
    if(event.cancel == true){
      navigationService.navigateBack();
      emit(await _buildState());
      return;
    }
    if (InputValidator.validateInput(
      password: passwordController.text,
      confirmPassword: passwordConfirmController.text,
    )) {
      await changeAccountPassword(ChangePasswordParams(newPassword: passwordController.text));
      navigationService.navigateBack();
      dialogService.showInfoSnackBar(const ShowInfoSnackBar(textKey: "page.change.password.changed"));
      emit(await _buildState());
    }
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
