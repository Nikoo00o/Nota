import 'dart:io';
import 'dart:ui';
import 'package:app/core/config/app_theme.dart';
import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/presentation/main/app/app_page.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:app/services/translation_service.dart';
import 'package:dargon2_flutter/dargon2_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';

Future<void> main(List<String> arguments) async {
  Logger.initLogger(Logger(logLevel: LogLevel.DEBUG));
  try {
    DArgon2Flutter.init(); // enable flutter argon2 for better performance
    WidgetsFlutterBinding.ensureInitialized();
    await initializeGetIt();
    _initErrorCallbacks();
    await sl<LocalDataSource>().init();
    Logger.initLogger(AppLogger(
      logLevel: await sl<AppSettingsRepository>().getLogLevel(),
      appConfig: sl(),
      appSettingsRepository: sl(),
    ));
    await sl<TranslationService>().init();

    final ThemeData theme = AppTheme.newTheme(darkTheme: await sl<AppSettingsRepository>().isDarkTheme());
    final Locale locale = sl<TranslationService>().currentLocale;
    Logger.info("Starting the app with ${theme.brightness == Brightness.dark ? "dark" : "light"} theme and the language "
        "code: ${locale.languageCode}");

    runApp(App(
      appConfig: sl(),
      appSettingsRepository: sl(),
      translationService: sl(),
      dialogService: sl(),
      sessionService: sl(),
      navigationService: sl(),
      activateLockscreen: sl(),
      initialLocale: locale,
      initialTheme: theme,
    ));
  } catch (e, s) {
    Logger.error("critical error starting the app", e, s);
  }
}

void _initErrorCallbacks() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _handleError(details.exception, details.stack ?? StackTrace.current);
  };
  // also handles the zone errors
  PlatformDispatcher.instance.onError = (Object error, StackTrace trace) {
    try {
      _handleError(error, trace);
      return true;
    } catch (_) {
      return false;
    }
  };
}

void _handleError(Object error, StackTrace trace) {
  if (error is BaseException) {
    Logger.error("Exception", error, trace);
    sl<DialogService>().show(ShowErrorDialog(
      descriptionKey: error.message ?? "error.unknown",
      descriptionKeyParams: error.messageParams,
    ));
    if (sl<NavigationService>().currentRoute != Routes.login) {
      if (error.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD ||
          error.message == ErrorCodes.httpStatusWith(HttpStatus.unauthorized)) {
        Logger.debug("logging out, because of ErrorCodes.ACCOUNT_WRONG_PASSWORD, or HttpStatus.unauthorized");
        sl<LogoutOfAccount>().call(const LogoutOfAccountParams(navigateToLoginPage: true)); // important: navigate to the
        // login page if the wrong password error is thrown anywhere, because it means that the password might have been
        // changed on a different device! the future can not be awaited here, but the dialog is shown to the user anyways.
      }
    }
  } else {
    Logger.error("Unknown Error", error, trace);
    sl<DialogService>().show(const ShowErrorDialog(descriptionKey: "error.unknown"));
  }
}
