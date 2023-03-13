import 'package:app/core/config/app_config.dart';
import 'package:app/core/constants/locales.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/usecases/account/change/activate_lock_screen.dart';
import 'package:app/presentation/main/app/app_bloc.dart';
import 'package:app/presentation/main/app/app_event.dart';
import 'package:app/presentation/main/app/app_state.dart';
import 'package:app/presentation/main/app/widgets/app_observer.dart';
import 'package:app/presentation/main/app/widgets/custom_app_localizations.dart';
import 'package:app/presentation/main/app/widgets/custom_navigator.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_page.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:app/services/session_service.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared/core/utils/logger/logger.dart';

import 'widgets/custom_scroll_behavior.dart';

/// The top level widget that builds the app itself with the widget subtree
class App extends StatelessWidget {
  final AppConfig appConfig;
  final AppSettingsRepository appSettingsRepository;
  final NavigationService navigationService;
  final TranslationService translationService;
  final DialogService dialogService;
  final SessionService sessionService;
  final ActivateLockscreen activateLockscreen;
  final Locale initialLocale;
  final ThemeData initialTheme;

  const App({
    required this.appConfig,
    required this.appSettingsRepository,
    required this.navigationService,
    required this.translationService,
    required this.dialogService,
    required this.sessionService,
    required this.activateLockscreen,
    required this.initialLocale,
    required this.initialTheme,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppBloc>(
      create: (_) {
        final AppBloc bloc = sl<AppBloc>();
        bloc.locale = initialLocale;
        bloc.theme = initialTheme;
        return bloc;
      },
      child: BlocBuilder<AppBloc, AppState>(
        builder: (BuildContext context, AppState state) {
          final ThemeData theme = _getTheme(state);
          _setSystemStatusBar(isDarkTheme: theme.brightness == Brightness.dark);
          return MaterialApp(
            title: appConfig.appTitle,
            theme: theme,
            debugShowCheckedModeBanner: false,
            scrollBehavior: const CustomScrollBehavior(),
            locale: state is AppStateInitialised ? state.locale : initialLocale,
            supportedLocales: Locales.supportedLocales,
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              CustomAppLocalizationsDelegate(translationService: translationService),
            ],
            home: _buildStructure(context, state),
            localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) =>
                _localeResolutionCallback(locale, supportedLocales, context),
          );
        },
      ),
    );
  }

  /// Builds the app observer around everything and then the dialog overlay above the custom navigator which displays the
  /// pages.
  Widget _buildStructure(BuildContext context, AppState state) {
    return AppObserver(
      dialogService: dialogService,
      sessionService: sessionService,
      navigationService: navigationService,
      appSettingsRepository: appSettingsRepository,
      activateLockscreen: activateLockscreen,
      child: DialogOverlayPage(
        child: _buildPage(context, state),
      ),
    );
  }

  /// Builds the page with the navigator and the safe area!
  Widget _buildPage(BuildContext context, AppState state) {
    return Container(
      color: _getTheme(state).colorScheme.background,
      child: SafeArea(
        child: CustomNavigator(
          navigationService: navigationService,
          appConfig: appConfig,
        ),
      ),
    );
  }

  ThemeData _getTheme(AppState state) => state is AppStateInitialised ? state.theme : initialTheme;

  void _setSystemStatusBar({required bool isDarkTheme}) =>
      SystemChrome.setSystemUIOverlayStyle(isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

  Locale _localeResolutionCallback(Locale? locale, Iterable<Locale> supportedLocales, BuildContext context) {
    late Locale result;
    if (supportedLocales.where((Locale other) => other.languageCode == locale?.languageCode).isNotEmpty) {
      result = locale!;
    } else {
      Logger.warn("Locale ${locale?.languageCode} was not supported");
      result = appConfig.defaultLocale;
    }
    BlocProvider.of<AppBloc>(context).add(AppUpdateLocale(result)); // make sure to also get system locale changes!
    return result;
  }
}
