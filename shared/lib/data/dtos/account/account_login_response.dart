import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/data/models/shared_account_model_mixin.dart';

class AccountLoginResponse extends AccountChangePasswordResponse {
  /// Base64 encoded
  final String encryptedDataKey;

  const AccountLoginResponse({
    required super.sessionToken,
    required this.encryptedDataKey,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...super.toJson(),
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
