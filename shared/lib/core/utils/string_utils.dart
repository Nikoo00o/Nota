import 'dart:math';
import 'dart:typed_data';

/// Returns a List of [length] with integer values from 0 to 255
Uint8List getRandomBytes(int length) {
  final Random random = Random.secure();
  return Uint8List.fromList(List<int>.generate(length, (int index) => random.nextInt(256))); // 0 to 255
}

/// Returns a String of [length] with character values from 0 to 255
String getRandomBytesAsString(int length) => String.fromCharCodes(getRandomBytes(length));
