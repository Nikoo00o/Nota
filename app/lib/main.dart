import 'dart:isolate';
import 'dart:ui';

import 'package:app/core/get_it.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:dargon2_flutter/dargon2_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:tuple/tuple.dart';

Future<void> main(List<String> arguments) async {
  Logger.initLogger(AppLogger(logLevel: LogLevel.VERBOSE));
  try {
    FlutterCryptography.enable(); // enable flutter cryptography for better performance
    DArgon2Flutter.init(); // enable flutter argon2 for better performance
    WidgetsFlutterBinding.ensureInitialized();
    await initializeGetIt();
    _initErrorCallbacks();
    await sl<LocalDataSource>().init();

    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Text("Test"),
        ),
      ),
    );
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
  //todo: show error dialog and log the error, etc
  Logger.error("flutter error", error, trace);
}
