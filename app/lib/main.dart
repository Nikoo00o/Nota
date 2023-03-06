import 'dart:ui';
import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/presentation/main/app/app_page.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:app/services/translation_service.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:dargon2_flutter/dargon2_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';

Future<void> main(List<String> arguments) async {
  Logger.initLogger(AppLogger(logLevel: LogLevel.VERBOSE));
  try {
    FlutterCryptography.enable(); // enable flutter cryptography for better performance
    DArgon2Flutter.init(); // enable flutter argon2 for better performance
    WidgetsFlutterBinding.ensureInitialized();
    await initializeGetIt();
    _initErrorCallbacks();
    await sl<LocalDataSource>().init();
    await sl<TranslationService>().init();
    Logger.debug("initialisation complete");

    runApp(App(
      appConfig: sl(),
      dialogService: sl(),
      sessionService: sl(),
      navigationService: sl(),
      activateScreenSaver: sl(),
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
    sl<DialogService>().showErrorDialog(error.message ?? "error.unknown", dialogTextKeyParams: error.messageParams);
    if (error.message == ErrorCodes.ACCOUNT_WRONG_PASSWORD && sl<NavigationService>().currentRoute != Routes.login) {
      sl<LogoutOfAccount>().call(const LogoutOfAccountParams(navigateToLoginPage: true)); // important: navigate to the login
      // page if the wrong password error  is thrown anywhere, because it means that the password might have been changed
      // on a different device!. the future can not be awaited here, but the dialog is shown to the user anyways.
    }
  } else {
    sl<DialogService>().showErrorDialog("error.unknown");
    Logger.error("Unknown Error", error, trace);
  }
}
