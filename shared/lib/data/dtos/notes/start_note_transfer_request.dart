import 'package:shared/data/dtos/request_dto.dart';
import 'package:shared/data/models/note_info_model.dart';

class StartNoteTransferRequest extends RequestDTO {
  /// The list of information about the client notes
  final List<NoteInfoModel> clientNotes;

  static const String JSON_CLIENT_NOTES = "JSON_CLIENT_NOTES";

  StartNoteTransferRequest({required this.clientNotes});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_CLIENT_NOTES: clientNotes,
    };
  }

  factory StartNoteTransferRequest.fromJson(Map<String, dynamic> map) {
    final List<dynamic> dynList = map[JSON_CLIENT_NOTES] as List<dynamic>;
    final List<NoteInfoModel> noteInfoList =
        dynList.map((dynamic element) => NoteInfoModel.fromJson(element as Map<String, dynamic>)).toList();

    return StartNoteTransferRequest(
      clientNotes: noteInfoList,
    );
  }
}
