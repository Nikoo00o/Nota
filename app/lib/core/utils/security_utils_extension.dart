import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/core/utils/string_utils.dart';

/// Offers the flutter specific security method which are faster and async in addition to the basic sync shared methods of
/// [SecurityUtils]
class SecurityUtilsExtension {
  static final AesGcm _asyncCipher = AesGcm.with256bits(nonceLength: SecurityUtils.IV_LENGTH);

  /// Calls [encryptAsync] after base64 decoding the [base64EncodedKey].
  static Future<Uint8List> encryptBytesAsync(Uint8List inputBytes, String base64EncodedKey) async {
    return encryptAsync(inputBytes, base64Decode(base64EncodedKey));
  }

  /// Calls [decryptAsync] after base64 decoding the [base64EncodedKey].
  static Future<Uint8List> decryptBytesAsync(Uint8List inputBytes, String base64EncodedKey) async {
    return decryptAsync(inputBytes, base64Decode(base64EncodedKey));
  }

  /// Will use AES GCM to encrypt the bytes by returning the iv and then the mac added before the cipher text.
  ///
  /// Uses a new random generated iv!
  ///
  /// This is the async version that is faster!
  static Future<Uint8List> encryptAsync(Uint8List inputBytes, Uint8List keyBytes) async {
    final Uint8List ivBytes = StringUtils.getRandomBytes(SecurityUtils.IV_LENGTH);
    final SecretBox secretBox = await _asyncCipher.encrypt(
      inputBytes,
      secretKey: SecretKeyData(keyBytes),
      nonce: ivBytes,
    );
    final Uint8List authenticationPart = StringUtils.combineLists(ivBytes, Uint8List.fromList(secretBox.mac.bytes));
    return StringUtils.combineLists(authenticationPart, Uint8List.fromList(secretBox.cipherText));
  }

  /// Will use AES GCM to decrypt the bytes by first checking the iv, then the mac of the bytes and then extracting the
  /// ciphertext
  ///
  /// This is the async version that is faster!
  static Future<Uint8List> decryptAsync(Uint8List inputBytes, Uint8List keyBytes) async {
    final Uint8List ivBytes = Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes, SecurityUtils.IV_LENGTH);
    final Uint8List macBytes =
        Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes + SecurityUtils.IV_LENGTH, SecurityUtils.MAC_LENGTH);

    final Uint8List cipherBytes = Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes + SecurityUtils.GCM_INFO_LENGTH,
        inputBytes.length - SecurityUtils.GCM_INFO_LENGTH);

    final SecretBox secretBox = SecretBox(cipherBytes, nonce: ivBytes, mac: Mac(macBytes));
    return Uint8List.fromList(await _asyncCipher.decrypt(secretBox, secretKey: SecretKeyData(keyBytes)));
  }
}
