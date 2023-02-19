/// The base Exception class which holds a message to display
class BaseException implements Exception {
  /// The message which can be a translation key to be translated, or it contains a description of the error
  final String? message;

  /// Optional message parameter for the [message] translation key to be included
  final List<String>? messageParams;

  const BaseException({required this.message, this.messageParams = const <String>[]});

  @override
  String toString() {
    return "$runtimeType: $message";
  }
}

class ServerException extends BaseException {
  const ServerException({required super.message, super.messageParams});
}

class FileException extends BaseException {
  const FileException({required super.message, super.messageParams});
}

class ClientException extends BaseException {
  const ClientException({required super.message, super.messageParams});
}
