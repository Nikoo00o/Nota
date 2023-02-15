import 'dart:io';
import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/data/dtos/response_dto.dart';
import 'package:shared/domain/entities/entity.dart';

/// The Result of a rest callback method which will be send to the client as a response
class RestCallbackResult extends Entity {
  /// The json map that should be returned to the client which will be converted to a string. It can also be empty
  final Map<String, dynamic> jsonResult;

  /// The http status code that should be returned to the client
  final int statusCode;

  /// Instead of returning a json map, you can also return raw data bytes.
  ///
  /// If this is not null, then [jsonResult] will not be used
  final List<int>? rawBytes;

  /// Contains additional response headers which should be send to the client. Otherwise this is empty.
  /// It has to be a modifiable map!!!
  /// Values for the keys [HttpHeaders.contentTypeHeader], [HttpHeaders.acceptHeader] and
  /// [HttpHeaders.contentLengthHeader] will be ignored, because they are set automatically to json, or octet-stream.
  late final Map<String, String> responseHeaders;

  /// Both Parameter have valid default values. If [rawBytes] is not null, it will replace [jsonResult]
  ///
  /// [responseHeaders] is optional and will be empty otherwise. It has to be a modifiable map!!!
  RestCallbackResult({
    this.jsonResult = const <String, dynamic>{},
    this.statusCode = HttpStatus.ok,
    this.rawBytes,
    Map<String, String>? responseHeaders,
  }) : super(<String, dynamic>{
          "jsonResult": jsonResult,
          "statusCode": statusCode,
          "rawBytes": rawBytes,
        }) {
    this.responseHeaders = responseHeaders ?? <String, String>{};
  }

  /// Returns a RestCallbackResult with a specific [errorCode] from [ErrorCodes] as a json map with the key
  /// [RestJsonParameter.SERVER_ERROR]
  ///
  /// The http [statusCode] is optional.
  factory RestCallbackResult.withErrorCode(String errorCode, {int statusCode = HttpStatus.ok}) {
    return RestCallbackResult(
      jsonResult: <String, dynamic>{RestJsonParameter.SERVER_ERROR: errorCode},
      statusCode: statusCode,
    );
  }

  /// Returns a RestCallbackResult with a specific [ResponseDTO] by calling toJson() on the dto.
  ///
  /// The [statusCode] is optional.
  factory RestCallbackResult.withResponse(ResponseDTO responseDTO, {int statusCode = HttpStatus.ok}) {
    return RestCallbackResult(jsonResult: responseDTO.toJson(), statusCode: statusCode);
  }

  /// Returns either the json map, or raw data list of bytes depending on which was set
  dynamic get data => rawBytes ?? jsonResult;
}
