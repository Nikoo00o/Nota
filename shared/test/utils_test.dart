import 'dart:typed_data';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/core/utils/string_utils.dart';
import 'package:test/test.dart';

void main() {
  test('getRandomBytes', () {
    expect(StringUtils.getRandomBytes(32).length, 32);
  });

  test('getRandomBytesAsBase64String', () {
    expect(StringUtils.getRandomBytesAsBase64String(32), isNot(StringUtils.getRandomBytesAsBase64String(32)));
  });

  test('combineLists', () {
    final Uint8List first = Uint8List.fromList(<int>[1, 2, 3]);
    final Uint8List second = Uint8List.fromList(<int>[4, 5, 6]);
    expect(StringUtils.combineLists(first, second), Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]));
  });

  test('encrypt and decrypt', () {
    const String clearText = "test text 1ä";
    final String base64Key = StringUtils.getRandomBytesAsBase64String(32);
    final String cipher = SecurityUtils.encryptString(clearText, base64Key);
    final String decrypted = SecurityUtils.decryptString(cipher, base64Key);
    expect(decrypted, clearText);
  });
}
