import 'package:shared/data/dtos/response_dto.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/data/models/shared_account_model_mixin.dart';

class AccountLoginResponse extends ResponseDTO {
  /// Base64 encoded
  final SessionTokenModel sessionToken;

  /// Base64 encoded
  final String encryptedDataKey;

  const AccountLoginResponse({
    required this.sessionToken,
    required this.encryptedDataKey,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      SharedAccountModelMixin.JSON_SESSION_TOKEN: sessionToken.toJson(),
      SharedAccountModelMixin.JSON_ENCRYPTED_DATA_KEY: encryptedDataKey,
    };
  }

  factory AccountLoginResponse.fromJson(Map<String, dynamic> map) {
    return AccountLoginResponse(
      sessionToken: SessionTokenModel.fromJson(map[SharedAccountModelMixin.JSON_SESSION_TOKEN] as Map<String, dynamic>),
      encryptedDataKey: map[SharedAccountModelMixin.JSON_ENCRYPTED_DATA_KEY] as String,
    );
  }
}
