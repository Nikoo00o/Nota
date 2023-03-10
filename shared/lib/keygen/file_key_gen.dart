import 'dart:io';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/string_utils.dart';

class FileKeyGen {

  static const int keyBytes = 32;

  static final String _slash = Platform.pathSeparator;

  static final String templatePath = FileUtils.getLocalFilePath("lib${_slash}keygen$_slash");

  static final String serverDataPath =
      FileUtils.getLocalFilePath("..${_slash}server${_slash}lib${_slash}core${_slash}config${_slash}sensitive_data.dart");

  static final String sharedDataPath =
      FileUtils.getLocalFilePath("lib${_slash}core${_slash}config${_slash}sensitive_data.dart");

  static void updateSensitiveData() {
    Logger.initLogger(Logger(logLevel: LogLevel.VERBOSE));

    String serverTemplate = FileUtils.readFile("${templatePath}server_sensitive_data.template");
    String sharedTemplate = FileUtils.readFile("${templatePath}shared_sensitive_data.template");

    serverTemplate = updateKeys(serverTemplate);

    sharedTemplate = updateKeys(sharedTemplate);
    sharedTemplate = keepServerHostName(sharedTemplate);

    FileUtils.writeFile(serverDataPath, serverTemplate);
    FileUtils.writeFile(sharedDataPath, sharedTemplate);
    Logger.info("Created new Keys and updated $serverDataPath and $sharedDataPath");
  }

  static String updateKeys(String input) {
    return input.replaceAllMapped("\$\$", (Match match) {
      return StringUtils.getRandomBytesAsBase64String(keyBytes);
    });
  }

  static String keepServerHostName(String input) {
    if (FileUtils.fileExists(sharedDataPath)) {
      final String oldFile = FileUtils.readFile(sharedDataPath);
      final RegExp regex = RegExp("static const String serverHostname =.*;?");
      final String? hostName = regex.allMatches(oldFile).first.group(0);
      if (hostName != null) {
        return input.replaceAllMapped(regex, (Match match) {
          return hostName;
        });
      }
    }
    return input;
  }
}

void main() => FileKeyGen.updateSensitiveData();
