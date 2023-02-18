import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/data/dtos/request_dto.dart';

/// The [toJson] for this request is used in the query params instead of the body data, so it returns a map of
/// <String, String>!
///
/// Uses [RestJsonParameter]
class DownloadNoteRequest extends RequestDTO {
    /// The connection to the transfer
    final String transferToken;

    /// The serverId of the target note that should be affected
    final int noteId;

    DownloadNoteRequest({required this.transferToken, required this.noteId});

    @override
    Map<String, dynamic> toJson() {
        return <String, String>{
            RestJsonParameter.TRANSFER_TOKEN: transferToken,
            RestJsonParameter.TRANSFER_NOTE_ID: noteId.toString(),
        };
    }

    factory DownloadNoteRequest.fromJson(Map<String, dynamic> map) {
        return DownloadNoteRequest(
            transferToken: map[RestJsonParameter.TRANSFER_TOKEN] as String,
            noteId: map[RestJsonParameter.TRANSFER_TOKEN] as int,
        );
    }
}
