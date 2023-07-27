import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
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

  /// Calls [encryptBytes] after base64 decoding the [base64EncodedKey].
  ///
  /// The result will be base64 encoded!
  static String encryptString(String input, String base64EncodedKey) {
    final Uint8List bytes = encryptBytes(Uint8List.fromList(utf8.encode(input)), base64Decode(base64EncodedKey));
    return base64UrlEncode(bytes);
  }

  /// Calls [decryptBytes] after base64 decoding the [base64EncryptedInput] and [base64EncodedKey].
  ///
  /// The result will be utf8 encoded (clear text).
  static String decryptString(String base64EncryptedInput, String base64EncodedKey) {
    final Uint8List bytes = decryptBytes(base64Decode(base64EncryptedInput), base64Decode(base64EncodedKey));
    return utf8.decode(bytes);
  }

  /// Will use AES GCM to encrypt the bytes by returning the iv and then the mac added before the cipher text.
  ///
  /// Uses a new random generated iv!
  static Uint8List encryptBytes(Uint8List inputBytes, Uint8List keyBytes) {
    if (inputBytes.isEmpty) {
      return Uint8List(0);
    }
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
  static Uint8List decryptBytes(Uint8List inputBytes, Uint8List keyBytes) {
    if (inputBytes.isEmpty) {
      return Uint8List(0);
    }
    if (inputBytes.length <= GCM_INFO_LENGTH) {
      Logger.error("$inputBytes are smaller than $GCM_INFO_LENGTH");
      throw const BaseException(message: "Decryption error");
    }
    final Uint8List ivBytes = Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes, IV_LENGTH);
    final Uint8List macBytes = Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes + IV_LENGTH, MAC_LENGTH);

    final Uint8List cipherBytes =
        Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes + GCM_INFO_LENGTH, inputBytes.length - GCM_INFO_LENGTH);

    final SecretBox secretBox = SecretBox(cipherBytes, nonce: ivBytes, mac: Mac(macBytes));
    return Uint8List.fromList(_cipher.decryptSync(secretBox, secretKeyData: SecretKeyData(keyBytes)));
  }

  /// Uses Sha256 to create a quick hash (should not be used for passwords)
  static Uint8List hashBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return Uint8List(0);
    }
    const DartSha256 algorithm = DartSha256();
    return Uint8List.fromList(algorithm.hashSync(bytes).bytes);
  }

  /// Uses Sha256 to create a quick hash (should not be used for passwords).
  ///
  /// The returned hash will be base 64 encoded!
  static String hashString(String input) {
    const DartSha256 algorithm = DartSha256();
    return base64UrlEncode(algorithm.hashSync(utf8.encode(input)).bytes);
  }
}
