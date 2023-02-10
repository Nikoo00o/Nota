import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class StringUtils {
  /// Returns a List of [length] with integer values from 0 to 255
  static Uint8List getRandomBytes(int length) {
    final Random random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (int index) => random.nextInt(256))); // 0 to 255
  }

  /// Returns a String of [length] with character values from 0 to 255
  static String getRandomBytesAsString(int length) => String.fromCharCodes(getRandomBytes(length));

  /// Returns a String with [length] bytes which are base64 url encoded.
  /// So the length of the string will be bigger!
  static String getRandomBytesAsBase64String(int length) => base64UrlEncode(getRandomBytes(length));
}
