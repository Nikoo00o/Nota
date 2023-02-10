import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/dart.dart';

class SecurityUtils {
  /// Uses Sha256 for a collision-resistant hash of [bytes].
  ///
  /// Sha512 could also be used for an even better collision resistance
  static Uint8List hashBytes(Uint8List bytes) {
    const DartSha256 algorithm = DartSha256();
    return Uint8List.fromList(algorithm.hashSync(bytes).bytes);
  }

  /// Returns a base 64 url encoded hash of the utf encoded [input]
  static String hashString(String input) {
    final Uint8List bytes = hashBytes(Uint8List.fromList(utf8.encode(input)));
    return base64UrlEncode(bytes);
  }
}
