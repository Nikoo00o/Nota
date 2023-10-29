import 'dart:io';

/// Loads a fixture file as a String from this fixture folder for testing.
///
/// The test must be started with the working directory being either the project root, or the test folder.
///
/// If [removeFormatting] is true, then all white space will be removed
String fixture(String name, {required bool removeFormatting}) {
  final File fixture = File(fixturePath(name));
  final String result = fixture.readAsStringSync();
  if (removeFormatting) {
    return result.replaceAll(RegExp(r"\s+"), "");
  } else {
    return result;
  }
}

/// returns the path to the fixture [name] inside of the fixture folder
///
/// The test must be started with the working directory being either the project root, or the test folder.
String fixturePath(String name) {
  String path = Directory.current.path;
  if (!path.endsWith("${Platform.pathSeparator}test")) {
    path = "$path${Platform.pathSeparator}test";
  }
  return '$path${Platform.pathSeparator}fixtures${Platform.pathSeparator}$name';
}
