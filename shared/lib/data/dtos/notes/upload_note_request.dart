import 'package:shared/data/dtos/notes/download_note_request.dart';

/// This only has [rawBytes] as additional data which is used for the body data and not inside of the query params!
class UploadNoteRequest extends DownloadNoteRequest {
  /// The raw encrypted bytes of the note
  final List<int> rawBytes;

  UploadNoteRequest({required super.transferToken, required super.noteId, required this.rawBytes});
}
