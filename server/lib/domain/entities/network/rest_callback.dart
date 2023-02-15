import 'dart:async';
import 'package:server/domain/entities/network/rest_callback_params.dart';
import 'package:server/domain/entities/network/rest_callback_result.dart';
import 'package:shared/core/network/endpoint.dart';
import 'package:shared/domain/entities/entity.dart';

/// Used in RestServer to store the callback functions
class RestCallback extends Entity {
  /// The endpoint for which this callback should be added for.
  ///
  /// Contains the api url and the http method which is used for this callback.
  final Endpoint endpoint;

  /// The callback function that will get called for the client requests
  final FutureOr<RestCallbackResult> Function(RestCallbackParams) callback;

  RestCallback({required this.endpoint, required this.callback})
      : super(<String, dynamic>{
          "endpoint": endpoint,
          "callback": callback,
        });
}
