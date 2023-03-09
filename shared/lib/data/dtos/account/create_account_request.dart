import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/models/shared_account_model_mixin.dart';

class CreateAccountRequest extends AccountLoginRequest {
  final String createAccountToken;

  /// Base64 encoded
  final String encryptedDataKey;

  static const String JSON_CREATE_ACCOUNT_TOKEN = "JSON_CREATE_ACCOUNT_TOKEN";

  const CreateAccountRequest({
    required this.createAccountToken,
    required super.username,
    required super.passwordHash,
    required this.encryptedDataKey,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_CREATE_ACCOUNT_TOKEN: createAccountToken,
      ...super.toJson(),
      SharedAccountModelMixin.JSON_ENCRYPTED_DATA_KEY: encryptedDataKey,
    };
  }

  factory CreateAccountRequest.fromJson(Map<String, dynamic> map) {
    return CreateAccountRequest(
      createAccountToken: map[JSON_CREATE_ACCOUNT_TOKEN] as String,
      username: map[SharedAccountModelMixin.JSON_USER_NAME] as String,
      passwordHash: map[SharedAccountModelMixin.JSON_PASSWORD_HASH] as String,
      encryptedDataKey: map[SharedAccountModelMixin.JSON_ENCRYPTED_DATA_KEY] as String,
    );
  }
}
