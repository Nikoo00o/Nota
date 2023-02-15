import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/utils/string_utils.dart';

/// Offers the shared basic synchronous security methods. For the async methods, look at [SecurityUtilsExtension]
class SecurityUtils {
  /// The iv bytes used for encrypting
  static const int IV_LENGTH = 12;

  /// The mac bytes used for decrypting (encryption adds those bytes at the front)
  static const int MAC_LENGTH = 16;

  /// The amount of bytes of the IV and MAC which are added before the cipher text
  static const int GCM_INFO_LENGTH = IV_LENGTH + MAC_LENGTH;

  static final DartAesGcm _cipher = DartAesGcm(
    secretKeyLength: SharedConfig.keyBytes,
    nonceLength: IV_LENGTH,
  );

  /// Calls [encrypt] after base64 decoding the [base64EncodedKey].
  static Uint8List encryptBytes(Uint8List inputBytes, String base64EncodedKey) {
    return encrypt(inputBytes, base64Decode(base64EncodedKey));
  }

  /// Calls [decrypt] after base64 decoding the [base64EncodedKey].
  static Uint8List decryptBytes(Uint8List inputBytes, String base64EncodedKey) {
    return decrypt(inputBytes, base64Decode(base64EncodedKey));
  }

  /// Will use AES GCM to encrypt the bytes by returning the iv and then the mac added before the cipher text.
  ///
  /// Uses a new random generated iv!
  static Uint8List encrypt(Uint8List inputBytes, Uint8List keyBytes) {
    final Uint8List ivBytes = StringUtils.getRandomBytes(IV_LENGTH);
    final SecretBox secretBox = _cipher.encryptSync(
      inputBytes,
      secretKeyData: SecretKeyData(keyBytes),
      nonce: ivBytes,
    );
    final Uint8List authenticationPart = StringUtils.combineLists(ivBytes, Uint8List.fromList(secretBox.mac.bytes));
    return StringUtils.combineLists(authenticationPart, Uint8List.fromList(secretBox.cipherText));
  }

  /// Will use AES GCM to decrypt the bytes by first checking the iv, then the mac of the bytes and then extracting the
  /// ciphertext
  static Uint8List decrypt(Uint8List inputBytes, Uint8List keyBytes) {
    final Uint8List ivBytes = Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes, IV_LENGTH);
    final Uint8List macBytes = Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes + IV_LENGTH, MAC_LENGTH);

    final Uint8List cipherBytes =
        Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes + GCM_INFO_LENGTH, inputBytes.length - GCM_INFO_LENGTH);

    final SecretBox secretBox = SecretBox(cipherBytes, nonce: ivBytes, mac: Mac(macBytes));
    return Uint8List.fromList(_cipher.decryptSync(secretBox, secretKeyData: SecretKeyData(keyBytes)));
  }
}
