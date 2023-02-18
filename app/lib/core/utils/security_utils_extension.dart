import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:shared/core/utils/security_utils.dart';
import 'package:shared/core/utils/string_utils.dart';

/// Offers the flutter specific security method which are faster and async in addition to the basic sync shared methods of
/// [SecurityUtils]
class SecurityUtilsExtension {
  static final AesGcm _asyncCipher = AesGcm.with256bits(nonceLength: SecurityUtils.IV_LENGTH);

  // t=1, p=1, m=47104, see https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#argon2id
  static final Argon2id _argon = Argon2id(
    memorySize: 47104,
    iterations: 1,
    parallelism: 1,
    hashLength: 32,
  );

  /// Calls [encryptBytesAsync] after base64 decoding the [base64EncodedKey].
  ///
  /// The result will be base64 encoded!
  static Future<String> encryptStringAsync(String input, String base64EncodedKey) async {
    final Uint8List bytes = await encryptBytesAsync(Uint8List.fromList(utf8.encode(input)), base64Decode(base64EncodedKey));
    return base64UrlEncode(bytes);
  }

  /// Calls [decryptBytesAsync] after base64 decoding the [base64EncryptedInput] and [base64EncodedKey].
  ///
  /// The result will be utf8 encoded (clear text).
  static Future<String> decryptStringAsync(String base64EncryptedInput, String base64EncodedKey) async {
    final Uint8List bytes = await decryptBytesAsync(base64Decode(base64EncryptedInput), base64Decode(base64EncodedKey));
    return utf8.decode(bytes);
  }

  /// Will use AES GCM to encrypt the bytes by returning the iv and then the mac added before the cipher text.
  ///
  /// Uses a new random generated iv!
  ///
  /// This is the async version that is faster!
  static Future<Uint8List> encryptBytesAsync(Uint8List inputBytes, Uint8List keyBytes) async {
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
  static Future<Uint8List> decryptBytesAsync(Uint8List inputBytes, Uint8List keyBytes) async {
    final Uint8List ivBytes = Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes, SecurityUtils.IV_LENGTH);
    final Uint8List macBytes =
        Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes + SecurityUtils.IV_LENGTH, SecurityUtils.MAC_LENGTH);

    final Uint8List cipherBytes = Uint8List.view(inputBytes.buffer, inputBytes.offsetInBytes + SecurityUtils.GCM_INFO_LENGTH,
        inputBytes.length - SecurityUtils.GCM_INFO_LENGTH);

    final SecretBox secretBox = SecretBox(cipherBytes, nonce: ivBytes, mac: Mac(macBytes));
    return Uint8List.fromList(await _asyncCipher.decrypt(secretBox, secretKey: SecretKeyData(keyBytes)));
  }

  /// This should be used to derive a key from a password, or to hash a password which should be stored.
  ///
  /// Uses Argon2id (winner of the password hashing competition 2015) for best security.
  static Future<List<int>> hashBytesSecure(List<int> bytes, List<int> salt) async {
    final SecretKey secretKey = await _argon.deriveKey(
      secretKey: SecretKey(bytes),
      nonce: salt,
    );
    return secretKey.extractBytes();
  }

  /// This should be used to derive a key from a password, or to hash a password which should be stored.
  ///
  /// Uses Argon2id (winner of the password hashing competition 2015) for best security.
  ///
  /// The returned hash will be base 64 encoded!
  static Future<String> hashStringSecure(String input, String base64EncodedSalt) async {
    final SecretKey secretKey = await _argon.deriveKey(
      secretKey: SecretKey(utf8.encode(input)),
      nonce: base64Decode(base64EncodedSalt),
    );
    final List<int> bytes = await secretKey.extractBytes();
    return base64UrlEncode(bytes);
  }
}
