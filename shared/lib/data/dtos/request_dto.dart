/// The request data transfer object base class that others server requests implement to override the toJson method.
///
/// The fromJson factory constructor must be provided as well in sub classes, but it can not be provided with an interface!
abstract class RequestDTO {
  const RequestDTO();

  /// Create JSON Map from request dto
  Map<String, dynamic> toJson();
}
