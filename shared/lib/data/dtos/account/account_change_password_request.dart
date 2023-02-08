import 'package:shared/data/dtos/request_dto.dart';
import 'package:shared/data/models/shared_account_model_mixin.dart';

class AccountChangePasswordRequest extends RequestDTO {
  /// Base64 encoded
  final String newPasswordHash;

  /// Base64 encoded
  final String newEncryptedDataKey;

  const AccountChangePasswordRequest({
    required this.newPasswordHash,
    required this.newEncryptedDataKey,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      SharedAccountModelMixin.JSON_PASSWORD_HASH: newPasswordHash,
      SharedAccountModelMixin.JSON_ENCRYPTED_DATA_KEY: newEncryptedDataKey,
    };
  }

  factory AccountChangePasswordRequest.fromJson(Map<String, dynamic> map) {
    return AccountChangePasswordRequest(
      newPasswordHash: map[SharedAccountModelMixin.JSON_PASSWORD_HASH] as String,
      newEncryptedDataKey: map[SharedAccountModelMixin.JSON_ENCRYPTED_DATA_KEY] as String,
    );
  }
}
