import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class StringUtils {
  /// Returns a List of [length] bytes with integer values from 0 to 255 which are cryptographically secure random numbers!
  static Uint8List getRandomBytes(int length) {
    final Random random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (int index) => random.nextInt(256))); // 0 to 255
  }

  static Uint8List combineLists(Uint8List first, Uint8List second) {
    final Uint8List result = Uint8List(first.length + second.length);
    for (int i = 0; i < first.length; i++) {
      result[i] = first[i];
    }
    for (int i = 0; i < second.length; i++) {
      result[i + first.length] = second[i];
    }
    return result;
  }

  /// Returns a String of [length] with character values from 0 to 255
  static String getRandomBytesAsString(int length) => String.fromCharCodes(getRandomBytes(length));

  /// Returns a String with [length] bytes which are base64 url encoded.
  /// So the length of the string will be bigger!
  static String getRandomBytesAsBase64String(int length) => base64UrlEncode(getRandomBytes(length));

  /// Returns a pretty string for an [object] with the [propertiesOfObject] which maps String description keys to
  /// the member variables of the object!
  static String toStringPretty(Object object, Map<String, Object?> propertiesOfObject) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln("\n${object.runtimeType} {");
    propertiesOfObject.forEach((String key, Object? value) {
      buffer.write("  $key : ");
      String valueString = value?.toString() ?? "null";
      if (valueString.startsWith("\n")) {
        valueString = valueString.substring(1); // remove the line break
        final List<String> innerLogs = valueString.split("\n");
        buffer.writeln(innerLogs.elementAt(0).toString()); // first line should not have spaces added
        for (int i = 1; i < innerLogs.length - 1; ++i) {
          buffer.writeln("  ${innerLogs.elementAt(i)}");
        }
        buffer.writeln("  ${innerLogs.elementAt(innerLogs.length - 1)},");
      } else {
        buffer.writeln("$valueString,");
      }
    });
    buffer.write("}");
    return buffer.toString();
  }
}
