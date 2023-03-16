import 'dart:io';

/// Loads a fixture file as a String from this fixture folder for testing.
///
/// The test must be started with the working directory being either the project root, or the test folder.
///
/// If [removeFormatting] is true, then all white space will be removed
String fixture(String name, {required bool removeFormatting}) {
  String path = Directory.current.path;
  if (!path.endsWith("${Platform.pathSeparator}test")) {
    path = "$path${Platform.pathSeparator}test";
  }
  final File fixture = File('$path${Platform.pathSeparator}fixtures${Platform.pathSeparator}$name');
  final String result = fixture.readAsStringSync();
  if (removeFormatting) {
    return result.replaceAll(RegExp(r"\s+"), "");
  } else {
    return result;
  }
}