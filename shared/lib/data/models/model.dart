/// The Model base class that other models implement to override the toJson method.
///
/// The fromJson factory constructor must be provided as well in sub classes, but it can not be provided with an interface!
abstract class Model {
    /// Create JSON Map from model
    Map<String, dynamic> toJson();
}
