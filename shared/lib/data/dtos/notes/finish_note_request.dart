import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/data/dtos/request_dto.dart';

class FinishNoteTransferRequest extends RequestDTO {
  /// This is [true] if this transfer should be cancelled and not be applied!
  ///
  /// Otherwise this transfer will be applied and others will be cancelled!
  final bool shouldCancel;

  static const String JSON_SHOULD_CANCEL = "JSON_SHOULD_CANCEL";

  FinishNoteTransferRequest({required this.shouldCancel});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_SHOULD_CANCEL: shouldCancel,
    };
  }

  factory FinishNoteTransferRequest.fromJson(Map<String, dynamic> map) {
    return FinishNoteTransferRequest(
      shouldCancel: map[JSON_SHOULD_CANCEL] as bool,
    );
  }
}

/// This version is for the client side and also contains the [transferToken] which will be used in the query params.
///
/// It does not affect to [toJson].
class FinishNoteTransferRequestWithTransferToken extends FinishNoteTransferRequest {
  /// The connection to the transfer which will be used as a query param with [RestJsonParameter.TRANSFER_TOKEN].
  final String transferToken;

  FinishNoteTransferRequestWithTransferToken({required this.transferToken, required super.shouldCancel});

  /// Returns [FinishNoteTransferRequestWithTransferToken] : [transferToken]
  Map<String, String> getQueryParams() {
    return <String, String>{
      RestJsonParameter.TRANSFER_TOKEN: transferToken,
    };
  }
}
