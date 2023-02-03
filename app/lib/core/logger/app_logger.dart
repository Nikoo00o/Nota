import 'package:flutter/widgets.dart';
import 'package:shared/core/utils/logger/logger.dart';

class AppLogger extends Logger {
  @override
  void logToConsole(String logMessage) {
    debugPrint(logMessage);
  }
}
