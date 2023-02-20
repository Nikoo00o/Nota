import 'package:flutter/widgets.dart';
import 'package:shared/core/utils/logger/logger.dart';

class AppLogger extends Logger {
  AppLogger({required super.logLevel});

  @override
  void logToConsole(String logMessage) {
    debugPrint(logMessage);
  }
}
