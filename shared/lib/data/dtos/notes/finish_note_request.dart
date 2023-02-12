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
