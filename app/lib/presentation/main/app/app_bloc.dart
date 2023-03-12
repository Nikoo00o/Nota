import 'package:app/core/config/app_theme.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/presentation/main/app/app_event.dart';
import 'package:app/presentation/main/app/app_state.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Handles the top level app events which every page can send to this bloc!
class AppBloc extends Bloc<AppEvent, AppState> {
  /// cached locale set by the page first
  late Locale locale;
  /// cached theme set by the page first
  late ThemeData theme;

  AppBloc() : super(const AppState()) {
    registerEventHandlers();
  }

  void registerEventHandlers() {
    on<UpdateLocale>(_handleUpdateLocale);
    on<UpdateTheme>(_handleUpdateTheme);
  }


  Future<void> _handleUpdateLocale(UpdateLocale event, Emitter<AppState> emit) async {
    locale = event.locale;
    emit(await _buildState());
  }

  Future<void> _handleUpdateTheme(UpdateTheme event, Emitter<AppState> emit) async {
    theme = AppTheme.newTheme(darkTheme: event.useDarkTheme);
    emit(await _buildState());
  }

  Future<AppState> _buildState() async => AppStateInitialised(locale: locale, theme: theme);

}
