import 'package:shared/core/constants/endpoints.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/data/dtos/account/account_change_password_request.dart';
import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';

/// The request methods can throw a [ServerException] with the documented error codes below in addition to the basic
/// [ErrorCodes] of the method [RestClient.sendRequest] which can be thrown in every request!
///
/// Of course the requests can also throw parsing exceptions on converting data themselves!
abstract class RemoteAccountDataSource {
  const RemoteAccountDataSource();

  /// Returns [ErrorCodes.SERVER_ACCOUNT_ALREADY_EXISTS] if the username already exists.
  /// Returns [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the request parameter are empty.
  /// Returns http status code 401 if the createAccountToken was invalid.
  Future<void> createAccountRequest(CreateAccountRequest request);

  /// Returns [ErrorCodes.SERVER_UNKNOWN_ACCOUNT] if the username was not found.
  /// Returns [ErrorCodes.SERVER_ACCOUNT_WRONG_PASSWORD] if the password hash was invalid.
  /// Returns [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the request parameter are empty.
  Future<AccountLoginResponse> loginRequest(AccountLoginRequest request);

  /// Returns [ErrorCodes.SERVER_INVALID_REQUEST_VALUES] if the request parameter are empty.
  /// This needs a logged in account, so it can also throw the errors of [FetchCurrentSessionToken]!
  Future<AccountChangePasswordResponse> changePasswordRequest(AccountChangePasswordRequest request);
}

class RemoteAccountDataSourceImpl extends RemoteAccountDataSource {
  final RestClient restClient;

  const RemoteAccountDataSourceImpl({required this.restClient});

  @override
  Future<void> createAccountRequest(CreateAccountRequest request) async {
    await restClient.sendJsonRequest(endpoint: Endpoints.ACCOUNT_CREATE, bodyData: request.toJson());
  }

  @override
  Future<AccountLoginResponse> loginRequest(AccountLoginRequest request) async {
    final Map<String, dynamic> json =
        await restClient.sendJsonRequest(endpoint: Endpoints.ACCOUNT_LOGIN, bodyData: request.toJson());
    return AccountLoginResponse.fromJson(json);
  }

  @override
  Future<AccountChangePasswordResponse> changePasswordRequest(AccountChangePasswordRequest request) async {
    final Map<String, dynamic> json =
        await restClient.sendJsonRequest(endpoint: Endpoints.ACCOUNT_CREATE, bodyData: request.toJson());
    return AccountChangePasswordResponse.fromJson(json);
  }
}
