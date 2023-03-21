import 'package:shared/data/dtos/response_dto.dart';
import 'package:shared/data/models/session_token_model.dart';
import 'package:shared/data/models/shared_account_model_mixin.dart';

class AccountChangePasswordResponse extends ResponseDTO {
  final SessionTokenModel sessionToken;

  const AccountChangePasswordResponse({
    required this.sessionToken,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      SharedAccountModelMixin.JSON_SESSION_TOKEN: sessionToken.toJson(),
    };
  }

  factory AccountChangePasswordResponse.fromJson(Map<String, dynamic> map) {
    return AccountChangePasswordResponse(
      sessionToken: SessionTokenModel.fromJson(map[SharedAccountModelMixin.JSON_SESSION_TOKEN] as Map<String, dynamic>),
    );
  }
}
