import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class FileUtils {
  /// Returns the absolute full file path for a local relative file path inside of the working directory (server, or client
  /// root)
  static String getLocalFilePath(String localPath) => "${Directory.current.path}${Platform.pathSeparator}$localPath";

  /// Read the content of the file as string
  static String readFile(String path) => File(path).readAsStringSync();

  /// Write the [content] as a file at the [path]
  static void writeFile(String path, String content) => File(path).writeAsStringSync(content);

  /// Returns the file encoding by parsing the contentType of the http headers
  static Encoding getEncoding(HttpHeaders headers) {
    late final MediaType mediaType;
    if (headers.contentType != null) {
      mediaType = MediaType.parse(headers.contentType!.value);
    } else {
      mediaType = MediaType('application', 'octet-stream');
    }
    return Encoding.getByName(mediaType.parameters['charset']) ?? latin1;
  }

  /// Creates the path structure with directories for the directory at the path. If the path points to a file, then it will
  /// create the parent directory.
  static void createDirectory(String path) {
    final Directory directory = _getDirectoryForPath(path);
    if (directory.existsSync() == false) {
      directory.createSync(recursive: true);
    }
  }

  /// Deletes the directory with the path, or if used with a file the parent directory
  static void deleteDirectory(String path) {
    final Directory directory = _getDirectoryForPath(path);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }

  /// Returns either the directory at [path], or the parent directory if [path] is a file
  static Directory _getDirectoryForPath(String path) {
    if (File(path).existsSync()) {
      return File(path).parent;
    } else {
      return Directory(path);
    }
  }
}
