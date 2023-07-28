import 'package:shared/data/dtos/request_dto.dart';
import 'package:shared/data/models/shared_account_model_mixin.dart';

class AccountLoginRequest extends RequestDTO {
  final String username;

  /// Base64 encoded
  final String passwordHash;

  /// Unique identifier for each build app / server pair
  final String createAccountToken;


  static const String JSON_CREATE_ACCOUNT_TOKEN = "JSON_CREATE_ACCOUNT_TOKEN";

  const AccountLoginRequest({
    required this.username,
    required this.passwordHash,
    required this.createAccountToken,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      SharedAccountModelMixin.JSON_USER_NAME: username,
      SharedAccountModelMixin.JSON_PASSWORD_HASH: passwordHash,
      JSON_CREATE_ACCOUNT_TOKEN: createAccountToken,
    };
  }

  factory AccountLoginRequest.fromJson(Map<String, dynamic> map) {
    return AccountLoginRequest(
      username: map[SharedAccountModelMixin.JSON_USER_NAME] as String,
      passwordHash: map[SharedAccountModelMixin.JSON_PASSWORD_HASH] as String,
      createAccountToken: map[JSON_CREATE_ACCOUNT_TOKEN] as String,
    );
  }
}
