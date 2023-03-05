import 'package:app/presentation/main/app/app_event.dart';
import 'package:app/presentation/main/app/app_state.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Handles the top level app events which every page can send to this bloc!
class AppBloc extends Bloc<AppEvent, AppState> {
  /// caches the current locale
  late Locale locale;

  AppBloc({
    required TranslationService translationService,
  })  : locale = translationService.currentLocale,
        super(AppState(translationService.currentLocale)) {
    registerEventHandlers();
  }

  void registerEventHandlers() {
    on<AppEventUpdateLocale>(_handleUpdateLocale);
  }

  void _handleUpdateLocale(AppEventUpdateLocale event, Emitter<AppState> emit) {
    locale = event.locale;
    emit(_buildState());
  }

  AppState _buildState() => AppState(locale);
}
