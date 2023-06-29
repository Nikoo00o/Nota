import 'dart:async';

import 'package:app/core/config/app_theme.dart';
import 'package:app/core/enums/app_update.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/presentation/main/app/app_event.dart';
import 'package:app/presentation/main/app/app_state.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// Handles the top level app events which every page can send to this bloc!
class AppBloc extends Bloc<AppEvent, AppState> {
  final TranslationService translationService;
  final AppSettingsRepository appSettingsRepository;

  /// cached locale set by the page first
  late Locale locale;

  /// cached theme set by the page first
  late ThemeData theme;

  /// gets the events from the [AppSettingsRepository]
  late final StreamSubscription<AppUpdate> streamSubscription;

  AppBloc({
    required this.translationService,
    required this.appSettingsRepository,
  }) : super(const AppState()) {
    registerEventHandlers();
    streamSubscription = appSettingsRepository.listen((AppUpdate update) async {
      // add event to emit a new state and rebuild depending on the change
      switch (update) {
        case AppUpdate.DARK_THEME:
          add(AppUpdateTheme(useDarkTheme: await appSettingsRepository.isDarkTheme()));
          break;
        case AppUpdate.LOCALE:
          add(AppUpdateLocale(await appSettingsRepository.getCurrentLocale()));
          break;
      }
    });
  }

  void registerEventHandlers() {
    on<AppUpdateLocale>(_handleUpdateLocale);
    on<AppUpdateTheme>(_handleUpdateTheme);
  }

  @mustCallSuper
  @override
  Future<void> close() async {
    await streamSubscription.cancel();
    return super.close();
  }

  Future<void> _handleUpdateLocale(AppUpdateLocale event, Emitter<AppState> emit) async {
    if (event.locale != locale) {
      locale = event.locale;
      await translationService.init(); //first load the new translation keys
      emit(await _buildState()); //then update ui
      Logger.info("Updated the locale to ${locale.languageCode}");
    }
  }

  Future<void> _handleUpdateTheme(AppUpdateTheme event, Emitter<AppState> emit) async {
    theme = AppTheme.newTheme(darkTheme: event.useDarkTheme);
    emit(await _buildState());
    Logger.debug("Updated the theme to ${event.useDarkTheme ? "dark" : "light"}");
  }

  Future<AppState> _buildState() async => AppStateInitialised(locale: locale, theme: theme);
}
