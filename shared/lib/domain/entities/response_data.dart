import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/domain/entities/entity.dart';

/// This is just a wrapper for the http response from [RestClient.sendRequest] and will contain either [json], or [bytes]
class ResponseData extends Entity {
  /// The json map send from the server. This will be null if [bytes] is not null
  final Map<String, dynamic>? json;

  /// The raw bytes send from the server. This will be null if [json] is not null
  final List<int>? bytes;

  /// The http headers from the response
  final Map<String, String> responseHeaders;

  ResponseData({required this.json, required this.bytes, required this.responseHeaders})
      : super(<String, dynamic>{
          "json": json,
          "bytes": bytes,
          "responseHeaders": responseHeaders,
        }) {
    assert((json != null || bytes != null) && !(json != null && bytes != null),
        "One of json, or bytes should be set in the response");
  }
}
