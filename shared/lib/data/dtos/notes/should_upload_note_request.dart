import 'package:shared/data/dtos/notes/download_note_request.dart';

/// Same as [DownloadNoteRequest]
class ShouldUploadNoteRequest extends DownloadNoteRequest {
  ShouldUploadNoteRequest({required super.transferToken, required super.noteId, required super.hashBytes});
}
