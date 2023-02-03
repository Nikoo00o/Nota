/// The base class for all other Exceptions which just holds a message that it displays.
///
/// Other more specific exceptions can add functionality like translation, or error codes, etc. You can have different
/// classes like a RepositoryException, UseCaseException, ClientException, ServerException, etc.
class BaseException implements Exception {
  final String? message;

  const BaseException({required this.message});

  @override
  String toString() {
    return "$runtimeType: $message";
  }
}

class ServerException extends BaseException {
  const ServerException({required super.message});
}
