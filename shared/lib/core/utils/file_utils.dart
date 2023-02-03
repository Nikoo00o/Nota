import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

/// Returns the full file path for a local relative file path inside of the working directory (server, or client root)
String getLocalFilePath(String localPath) => "${Directory.current.path}${Platform.pathSeparator}$localPath";

/// Read the content of the file as string
String readFile(String path) => File(path).readAsStringSync();

/// Write the [content] as a file at the [path]
void writeFile(String path, String content) => File(path).writeAsStringSync(content);

/// Returns the file encoding by parsing the contentType of the http headers
Encoding getEncoding(HttpHeaders headers) {
  late final MediaType mediaType;
  if (headers.contentType != null) {
    mediaType = MediaType.parse(headers.contentType!.value);
  } else {
    mediaType = MediaType('application', 'octet-stream');
  }
  return Encoding.getByName(mediaType.parameters['charset']) ?? latin1;
}
