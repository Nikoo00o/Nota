import 'package:app/core/config/app_config.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/remote_account_data_source.dart';
import 'package:app/data/models/client_account_model.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/data/dtos/account/account_change_password_request.dart';
import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';

class AccountRepositoryImpl extends AccountRepository {
  final RemoteAccountDataSource remoteAccountDataSource;
  final LocalDataSource localDataSource;
  final AppConfig appConfig;

  ClientAccount? _cachedAccount;

  AccountRepositoryImpl({required this.remoteAccountDataSource, required this.localDataSource, required this.appConfig});

  @override
  Future<ClientAccount?> getAccount() async => _cachedAccount ??= await localDataSource.loadAccount();

  @override
  Future<void> saveAccount(ClientAccount account) async {
    _cachedAccount = account;
    await localDataSource.saveAccount(ClientAccountModel.fromServerAccount(_cachedAccount!));
  }

  @override
  Future<void> createNewAccount() async {
    final ClientAccount account = await _getAccountAndThrowIfNull();
    await remoteAccountDataSource.createAccountRequest(CreateAccountRequest(
      createAccountToken: appConfig.createAccountToken,
      userName: account.userName,
      passwordHash: account.passwordHash,
      encryptedDataKey: account.encryptedDataKey,
    ));
  }

  @override
  Future<ClientAccount> login() async {
    final ClientAccount account = await _getAccountAndThrowIfNull();
    final AccountLoginResponse response = await remoteAccountDataSource.loginRequest(AccountLoginRequest(
      userName: account.userName,
      passwordHash: account.passwordHash,
    ));
    account.sessionToken = response.sessionToken;
    account.encryptedDataKey = response.encryptedDataKey;
    return account;
  }

  @override
  Future<ClientAccount> updatePasswordOnServer() async {
    final ClientAccount account = await _getAccountAndThrowIfNull();
    final AccountChangePasswordRequest request = AccountChangePasswordRequest(
      newPasswordHash: account.passwordHash,
      newEncryptedDataKey: account.encryptedDataKey,
    );
    final AccountChangePasswordResponse response = await remoteAccountDataSource.changePasswordRequest(request);
    account.sessionToken = response.sessionToken;
    return account;
  }

  Future<ClientAccount> _getAccountAndThrowIfNull() async {
    final ClientAccount? account = await getAccount();
    if (account == null) {
      throw const ClientException(message: ErrorCodes.CLIENT_NO_ACCOUNT);
    } else {
      return account;
    }
  }
}
