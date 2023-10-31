import 'package:shared/core/constants/rest_json_parameter.dart';
import 'note_request.dart';

/// The [toJson] for this request is used in the query params instead of the body data, so it returns a map of
/// <String, String>!
///
/// only the [hashBytes] are used in the body of the request and are not included in the from/to json methods. if
/// this is null, or empty, then no hash should be compared
///
/// Uses [RestJsonParameter]
class DownloadNoteRequest extends NoteRequest {
  /// The hash of the raw encrypted bytes of the note. can be null if nothing should/can be compared
  final List<int>? hashBytes;

  DownloadNoteRequest({required super.transferToken, required super.noteId, required this.hashBytes});
}
