import 'package:shared/data/dtos/response_dto.dart';
import 'package:shared/data/models/note_update_model.dart';

class StartNoteTransferResponse extends ResponseDTO {
  /// The new base64 encoded transfer token that should be used for the created transfer
  final String transferToken;

  /// The note transfers with the status, id, name, etc of each note after comparing server and client notes.
  ///
  /// The Client can now already update the [NoteUpdateModel.newEncFileName] and also update those notes which still have
  /// a [NoteUpdateModel.clientId] that is different than [NoteUpdateModel.serverId]. And it can also delete the notes
  /// with an empty file name.
  final List<NoteUpdateModel> noteTransfers;

  static const String JSON_TRANSFER_TOKEN = "JSON_TRANSFER_TOKEN";
  static const String JSON_NOTE_TRANSFERS = "JSON_NOTE_TRANSFERS";

  StartNoteTransferResponse({required this.transferToken, required this.noteTransfers});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_TRANSFER_TOKEN: transferToken,
      JSON_NOTE_TRANSFERS: noteTransfers,
    };
  }

  factory StartNoteTransferResponse.fromJson(Map<String, dynamic> map) {
    final List<dynamic> dynList = map[JSON_NOTE_TRANSFERS] as List<dynamic>;
    final List<NoteUpdateModel> noteTransferList =
        dynList.map((dynamic element) => NoteUpdateModel.fromJson(element as Map<String, dynamic>)).toList();

    return StartNoteTransferResponse(
      transferToken: map[JSON_TRANSFER_TOKEN] as String,
      noteTransfers: noteTransferList,
    );
  }
}
