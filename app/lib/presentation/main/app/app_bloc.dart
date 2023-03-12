import 'package:app/core/config/app_theme.dart';
import 'package:app/presentation/main/app/app_event.dart';
import 'package:app/presentation/main/app/app_state.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// Handles the top level app events which every page can send to this bloc!
class AppBloc extends Bloc<AppEvent, AppState> {
  final TranslationService translationService;

  /// cached locale set by the page first
  late Locale locale;

  /// cached theme set by the page first
  late ThemeData theme;

  AppBloc({
    required this.translationService,
  }) : super(const AppState()) {
    registerEventHandlers();
  }

  void registerEventHandlers() {
    on<AppUpdateLocale>(_handleUpdateLocale);
    on<AppUpdateTheme>(_handleUpdateTheme);
  }

  Future<void> _handleUpdateLocale(AppUpdateLocale event, Emitter<AppState> emit) async {
    if(event.locale!=locale){
      locale = event.locale;
      await translationService.init();//first load the new translation keys
      emit(await _buildState());//then update ui
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
