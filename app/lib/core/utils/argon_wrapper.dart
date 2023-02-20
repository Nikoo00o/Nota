import 'package:dargon2_flutter/dargon2_flutter.dart';

/// Wraps the calls to argon2 which is platform specific code!
/// For testing, there will be a mock encryption.
abstract class ArgonWrapper {
  Future<List<int>> hashBytesSecure(List<int> bytes, List<int> saltBytes, int hashLength);
}

class ArgonWrapperImpl extends ArgonWrapper {
  @override
  Future<List<int>> hashBytesSecure(List<int> bytes, List<int> saltBytes, int hashLength) async {
    final Salt salt = Salt(saltBytes);
    // t=3, p=1, m=12288 , see https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#argon2id
    final DArgon2Result result = await argon2.hashPasswordBytes(
      bytes,
      salt: salt,
      iterations: 3,
      parallelism: 1,
      memory: 12288,
      length: hashLength,
      type: Argon2Type.id,
    );
    return result.rawBytes;
  }
}
