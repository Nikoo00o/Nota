/// The response data transfer object base class that others server responses implement to override the toJson method.
///
/// The fromJson factory constructor must be provided as well in sub classes, but it can not be provided with an interface!
abstract class ResponseDTO {
  const ResponseDTO();

  /// Create JSON Map from request dto
  Map<String, dynamic> toJson();
}
