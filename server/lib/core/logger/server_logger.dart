import 'dart:io';

import 'package:server/core/config/server_config.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/log_message.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:intl/intl.dart';

class ServerLogger extends Logger {
  final ServerConfig serverConfig;

  ServerLogger({required super.logLevel, required this.serverConfig});

  @override
  Future<void> logToStorage(LogMessage logMessage) async {
    if (serverConfig.logIntoStorage) {
      try {
        final String date = DateFormat("yyyy-MM-dd").format(DateTime.now());
        final String path = "${serverConfig.logFolder}${Platform.pathSeparator}$date.txt";
        await FileUtils.addToFileAsync(path, logMessage.toString());
        final String delimiter = String.fromCharCodes(List<int>.generate(100, (int index) => "-".codeUnits.first));
        await FileUtils.addToFileAsync(path, "\n$delimiter\n");
      } catch (_) {
        //ignored
      }
    }
  }
}
