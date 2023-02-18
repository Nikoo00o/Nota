import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/data/dtos/account/account_change_password_request.dart';
import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';

class RemoteAccountDataSource {
  final RestClient restClient;

  const RemoteAccountDataSource({required this.restClient});

  Future<void> createAccountRequest(CreateAccountRequest request) async {

  }

  Future<AccountLoginResponse> loginRequest(AccountLoginRequest request) async {
    throw UnimplementedError();
  }

  Future<AccountChangePasswordResponse> changePasswordRequest(AccountChangePasswordRequest request) async {
    throw UnimplementedError();
  }
}
