import 'dart:convert';
import 'dart:io';

import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/core/utils/string_utils.dart';

class FileKeyGen {
  static final String _slash = Platform.pathSeparator;

  static final String templatePath = getLocalFilePath("lib${_slash}keygen$_slash");

  static final String serverDataPath = getLocalFilePath(""
      "..${_slash}server${_slash}lib${_slash}config${_slash}sensitive_data.dart");

  static final String sharedDataPath = getLocalFilePath("lib${_slash}core${_slash}config${_slash}sensitive_data.dart");

  static void updateSensitiveData() {
    Logger.initLogger(Logger());

    String serverTemplate = readFile("${templatePath}server_sensitive_data.template");
    String sharedTemplate = readFile("${templatePath}shared_sensitive_data.template");

    serverTemplate = updateKeys(serverTemplate);

    sharedTemplate = updateKeys(sharedTemplate);
    sharedTemplate = keepServerHostName(sharedTemplate);

    writeFile(serverDataPath, serverTemplate);
    writeFile(sharedDataPath, sharedTemplate);
    Logger.info("Created new Keys and updated $serverDataPath and $sharedDataPath");
  }

  static String updateKeys(String input) {
    return input.replaceAllMapped("\$\$", (Match match) {
      return getRandomBytesAsBase64String(SharedConfig.keyBytes);
    });
  }

  static String keepServerHostName(String input) {
    if (File(sharedDataPath).existsSync()) {
      final String oldFile = readFile(sharedDataPath);
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
