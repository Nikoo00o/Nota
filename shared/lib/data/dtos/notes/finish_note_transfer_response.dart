import 'package:shared/data/dtos/response_dto.dart';

class FinishNoteTransferResponse extends ResponseDTO {
  /// The note ids of the client as keys mapped to the new server ids of those notes as values for the notes that need
  /// to be updated after the transfer!
  final Map<int, int> clientToServerIds;

  static const String JSON_CLIENT_TO_SERVER_IDS = "JSON_CLIENT_TO_SERVER_IDS";

  FinishNoteTransferResponse({required this.clientToServerIds});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_CLIENT_TO_SERVER_IDS:
          clientToServerIds.map((int key, int value) => MapEntry<String, String>(key.toString(), value.toString())),
    };
  }

  factory FinishNoteTransferResponse.fromJson(Map<String, dynamic> map) {
    final Map<String, String> stringIds = map[JSON_CLIENT_TO_SERVER_IDS] as Map<String, String>;
    return FinishNoteTransferResponse(
      clientToServerIds: stringIds.map((String key, String value) => MapEntry<int, int>(int.parse(key), int.parse(value))),
    );
  }
}
