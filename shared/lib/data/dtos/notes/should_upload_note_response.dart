import 'package:shared/data/dtos/response_dto.dart';

/// if the client should update the current affected note to the server. false if the content did not change
class ShouldUploadNoteResponse extends ResponseDTO {
  final bool shouldUpload;

  static const String JSON_SHOULD_UPLOAD = "JSON_SHOULD_UPLOAD";

  ShouldUploadNoteResponse({required this.shouldUpload});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_SHOULD_UPLOAD: shouldUpload,
    };
  }

  factory ShouldUploadNoteResponse.fromJson(Map<String, dynamic> map) {
    return ShouldUploadNoteResponse(shouldUpload: map[JSON_SHOULD_UPLOAD] as bool);
  }
}
