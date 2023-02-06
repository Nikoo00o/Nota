/// The HttpMethod used for the REST API
enum HttpMethod {
  /// retrieving resources
  GET,

  /// creating resources
  POST,

  /// updating resources
  PUT,

  /// deleting resources
  DELETE,

  /// only used for defining a new RestCallback which accepts each http method.
  ALL;

  factory HttpMethod.fromString(String data) {
    return values.firstWhere((HttpMethod element) => element.name == data);
  }

  @override
  String toString() {
    return name;
  }
}
