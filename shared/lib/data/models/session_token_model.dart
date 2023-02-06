import 'package:shared/data/models/model.dart';
import 'package:shared/domain/entities/session_token.dart';

class SessionTokenModel extends SessionToken implements Model {
  static const String JSON_TOKEN = "JSON_TOKEN";
  static const String JSON_VALID_TO = "JSON_VALID_TO";

  SessionTokenModel({required super.token, required super.validTo});

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_TOKEN: token,
      JSON_VALID_TO: validTo.toIso8601String(),
    };
  }

  factory SessionTokenModel.fromJson(Map<String, dynamic> json) {
    return SessionTokenModel(
      token: json[JSON_TOKEN] as String,
      validTo: DateTime.parse(json[JSON_VALID_TO] as String),
    );
  }

  factory SessionTokenModel.fromSessionToken(SessionToken entity) {
    if (entity is SessionTokenModel) {
      return entity;
    }
    return SessionTokenModel(token: entity.token, validTo: entity.validTo);
  }
}
