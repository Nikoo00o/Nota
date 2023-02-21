import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';

class NetworkUtils {
  /// Modifies the [httpHeaders] Content-Type depending on if [data] is a json Map<String, dynamic>, or a List<int> of raw
  /// bytes if the header value is not already set.
  /// This will also set the "Accept" and "Content-Length" header if they are not set.
  ///
  /// If [data] is a json map, it will also get encoded to bytes
  ///
  /// If [data] if none of those, a [ServerException] with [ErrorCodes.INVALID_DATA_TYPE] will be thrown!
  /// If [data] is null, an empty list will be returned.
  static List<int> encodeNetworkData({required Map<String, String> httpHeaders, required dynamic data}) {
    httpHeaders[HttpHeaders.acceptHeader] = "${ContentType.json},${ContentType.binary}";
    if (data == null) {
      return List<int>.empty(growable: true);
    } else if (data is List<int>) {
      httpHeaders[HttpHeaders.contentTypeHeader] = ContentType.binary.toString();
      httpHeaders[HttpHeaders.contentLengthHeader] = data.length.toString();
      return data;
    } else if (data is Map<String, dynamic>) {
      final String jsonData = jsonEncode(data);
      httpHeaders[HttpHeaders.contentTypeHeader] = ContentType.json.toString();
      final List<int> bytes = getEncoding(httpHeaders).encode(jsonData);
      httpHeaders[HttpHeaders.contentLengthHeader] = bytes.length.toString();
      return bytes;
    }
    Logger.error("Error encoding data with an type for headers: $httpHeaders");
    throw const ServerException(message: ErrorCodes.INVALID_DATA_TYPE);
  }

  /// Should decode the network [data] depending on the [httpHeaders] and either return a Map<String, dynamic>, a
  /// List<int>, or "null" if the data was empty.
  ///
  /// If the content type header does not match the type of the bytes, or if the content type header is missing, then
  /// a [ServerException] with [ErrorCodes.INVALID_DATA_TYPE] will be thrown!
  static dynamic decodeNetworkData({required Map<String, String> httpHeaders, required Uint8List data}) {
    if (data.isEmpty) {
      return null;
    } else if (httpHeaders[HttpHeaders.contentTypeHeader] == ContentType.binary.toString()) {
      return data;
    } else if (httpHeaders[HttpHeaders.contentTypeHeader] == ContentType.json.toString()) {
      String? dataString;
      try {
        dataString = getEncoding(httpHeaders).decode(data);
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (e) {
        Logger.warn("Could not decode json string: $dataString");
      }
    }
    Logger.error("Error decoding data with an invalid content type for headers: $httpHeaders");
    throw const ServerException(message: ErrorCodes.INVALID_DATA_TYPE);
  }

  /// Should decode the network [data] depending on the [httpHeaders] and either return a Map<String, dynamic>, a
  /// List<int>, or "null" if the data was empty.
  ///
  /// If the content type header does not match the type of the bytes, or if the content type header is missing, then
  /// a [ServerException] with [ErrorCodes.INVALID_DATA_TYPE] will be thrown!
  static dynamic decodeNetworkDataStream({required Map<String, String> httpHeaders, required Stream<Uint8List> data}) async {
    if (httpHeaders[HttpHeaders.contentTypeHeader]?.contains(ContentType.binary.subType) ?? false) {
      final List<int> finalBytes = List<int>.empty(growable: true);
      await for (final Uint8List list in data) {
        finalBytes.addAll(list);
      }
      return finalBytes;
    } else if (httpHeaders[HttpHeaders.contentTypeHeader]?.contains(ContentType.json.subType) ?? false) {
      String? dataString;
      try {
        dataString = await getEncoding(httpHeaders).decodeStream(data);
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (e) {
        Logger.warn("Could not decode json string: $dataString");
      }
    } else {
      final bool gotNoData = await data.isEmpty;
      if (gotNoData) {
        return null;
      }
    }
    Logger.error("Error decoding data with an invalid content type for headers: $httpHeaders");
    throw const ServerException(message: ErrorCodes.INVALID_DATA_TYPE);
  }

  /// Returns the file encoding by parsing the contentType of the http headers, or utf8 if none was found!
  static Encoding getEncoding(Map<String, String> httpHeaders) {
    MediaType? mediaType;
    try {
      if (httpHeaders.containsKey(HttpHeaders.contentTypeHeader)) {
        mediaType = MediaType.parse(httpHeaders[HttpHeaders.contentTypeHeader]!);
      } else {
        mediaType = MediaType('application', 'octet-stream');
      }
    } catch (_) {}
    return Encoding.getByName(mediaType?.parameters['charset']) ?? utf8;
  }
}

extension HttpHeaderExtension on HttpHeaders {
  Map<String, String> asMap() {
    final Map<String, String> headerMap = <String, String>{};
    forEach((String name, List<String> valueList) {
      if (valueList.isNotEmpty) {
        headerMap[name] = valueList.first;
      }
    });
    return headerMap;
  }
}
