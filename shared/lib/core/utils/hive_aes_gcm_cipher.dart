import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:shared/core/utils/security_utils.dart';

/// Default encryption algorithm. Uses AES256 CBC with PKCS7 padding.
class HiveAesGcmCipher implements HiveCipher {
  final Uint8List keyBytes;

  HiveAesGcmCipher({required this.keyBytes}) {
    assert(keyBytes.isNotEmpty, "key may not be empty");
  }

  @override
  int encrypt(Uint8List inp, int inpOff, int inpLength, Uint8List out, int outOff) {
    final Uint8List inputBytes = Uint8List.view(inp.buffer, inpOff, inpLength);
    final Uint8List decryptedBytes = SecurityUtils.encryptBytes(inputBytes, keyBytes);
    out.setAll(outOff, decryptedBytes);
    return decryptedBytes.length;
  }

  @override
  int decrypt(Uint8List inp, int inpOff, int inpLength, Uint8List out, int outOff) {
    final Uint8List inputBytes = Uint8List.view(inp.buffer, inpOff, inpLength);
    final Uint8List encryptedBytes = SecurityUtils.decryptBytes(inputBytes, keyBytes);
    out.setAll(outOff, encryptedBytes);
    return encryptedBytes.length;
  }

  @override
  int calculateKeyCrc() => 0;

  @override
  int maxEncryptedSize(Uint8List inp) => inp.length + SecurityUtils.IV_LENGTH + SecurityUtils.MAC_LENGTH;
}
