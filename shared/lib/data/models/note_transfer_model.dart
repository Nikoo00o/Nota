import 'package:shared/core/enums/note_transfer_status.dart';
import 'package:shared/data/models/model.dart';

class NoteTransferModel implements Model {
  /// Even tho this is send from server to client, it needs to save the client id of the notes, because the client might
  /// not know the server id yet!
  final int clientId;

  /// This is only not null if the notes time stamp on the server was more recent and the not had a different name.
  ///
  /// Important: if the name is empty (not null!), then the file should be deleted!!!
  final String? newEncFileName;

  /// If Server, or client had a newer version of the file and the other one needs updating
  final NoteTransferStatus noteTransferStatus;

  static const String JSON_CLIENT_ID = "JSON_CLIENT_ID";
  static const String JSON_NEW_ENCRYPTED_FILE_NAME = "JSON_NEW_ENCRYPTED_FILE_NAME";
  static const String JSON_TRANSFER_STATUS = "JSON_TRANSFER_STATUS";

  NoteTransferModel({required this.clientId, required this.newEncFileName, required this.noteTransferStatus});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_CLIENT_ID: clientId,
      JSON_NEW_ENCRYPTED_FILE_NAME: newEncFileName,
      JSON_TRANSFER_STATUS: noteTransferStatus.toString(),
    };
  }

  factory NoteTransferModel.fromJson(Map<String, dynamic> json) {
    return NoteTransferModel(
      clientId: (json[JSON_CLIENT_ID] as num).toInt(),
      newEncFileName: json[JSON_NEW_ENCRYPTED_FILE_NAME] as String,
      noteTransferStatus: NoteTransferStatus.fromString(json[JSON_TRANSFER_STATUS] as String),
    );
  }

  bool get wasFileNameChanged => newEncFileName != null;

  bool get wasFileDeleted => newEncFileName?.isEmpty ?? false;
}
