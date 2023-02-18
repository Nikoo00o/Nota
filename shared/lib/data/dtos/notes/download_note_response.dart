import 'package:shared/data/dtos/response_dto.dart';

/// Currently this is just a wrapper for the [rawBytes] and it does not have any data for the [toJson] yet!
class DownloadNoteResponse extends ResponseDTO {
  /// The raw encrypted bytes of the note
  final List<int> rawBytes;

  DownloadNoteResponse({required this.rawBytes});

  /// Not implemented
  @override
  Map<String, dynamic> toJson() => throw UnimplementedError();
}
