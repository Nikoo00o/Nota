import 'package:shared/data/dtos/request_dto.dart';
import 'package:shared/data/models/shared_account_model_mixin.dart';

class AccountLoginRequest extends RequestDTO {
  final String userName;

  /// Base64 encoded
  final String passwordHash;

  const AccountLoginRequest({
    required this.userName,
    required this.passwordHash,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      SharedAccountModelMixin.JSON_USER_NAME: userName,
      SharedAccountModelMixin.JSON_PASSWORD_HASH: passwordHash,
    };
  }

  factory AccountLoginRequest.fromJson(Map<String, dynamic> map) {
    return AccountLoginRequest(
      userName: map[SharedAccountModelMixin.JSON_USER_NAME] as String,
      passwordHash: map[SharedAccountModelMixin.JSON_PASSWORD_HASH] as String,
    );
  }
}
