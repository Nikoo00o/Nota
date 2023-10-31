import 'package:shared/core/constants/rest_json_parameter.dart';
import 'package:shared/data/dtos/notes/note_request.dart';

/// The [toJson] for this request is used in the query params instead of the body data, so it returns a map of
/// <String, String>!
///
/// This only has [rawBytes] as additional data which is used for the body data and not inside of the query params!
/// so it is not included in the from/to json methods!
///
/// Uses [RestJsonParameter]
class UploadNoteRequest extends NoteRequest {
  /// The raw encrypted bytes of the note (the content)
  final List<int> rawBytes;

  UploadNoteRequest({required super.transferToken, required super.noteId, required this.rawBytes});
}
