import 'package:app/core/config/app_config.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/remote_account_data_source.dart';
import 'package:app/data/models/client_account_model.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/dtos/account/account_change_password_request.dart';
import 'package:shared/data/dtos/account/account_change_password_response.dart';
import 'package:shared/data/dtos/account/account_login_request.dart.dart';
import 'package:shared/data/dtos/account/account_login_response.dart';
import 'package:shared/data/dtos/account/create_account_request.dart';
import 'package:shared/domain/entities/note_info.dart';

class AccountRepositoryImpl extends AccountRepository {
  final RemoteAccountDataSource remoteAccountDataSource;
  final LocalDataSource localDataSource;
  final AppConfig appConfig;

  ClientAccount? _cachedAccount;

  AccountRepositoryImpl({required this.remoteAccountDataSource, required this.localDataSource, required this.appConfig});

  @override
  Future<ClientAccount?> getAccount({bool forceLoad = false}) async {
    if (_cachedAccount == null || forceLoad) {
      final ClientAccount? oldAccount = _cachedAccount;
      _cachedAccount = await localDataSource.loadAccount();
      Logger.verbose("Replaced the cached account $oldAccount\nwith the stored account $_cachedAccount");
    }
    return _cachedAccount;
  }

  @override
  Future<ClientAccount> getAccountAndThrowIfNull() async {
    final ClientAccount? account = await getAccount();
    if (account == null) {
      Logger.error("No account is saved");
      throw const ClientException(message: ErrorCodes.CLIENT_NO_ACCOUNT);
    } else {
      return account;
    }
  }

  @override
  Future<void> saveAccount(ClientAccount? account) async {
    if (Logger.canLog(LogLevel.VERBOSE)) {
      final ClientAccount? oldAccount = await localDataSource.loadAccount();
      if (_cachedAccount != oldAccount) {
        Logger.verbose("Replaced the stored account $oldAccount\nwith the cached account $_cachedAccount");
      }
    }
    _cachedAccount = account;
    if (_cachedAccount != null) {
      await localDataSource.saveAccount(ClientAccountModel.fromClientAccount(_cachedAccount!));
    } else {
      await localDataSource.saveAccount(null);
    }
  }

  @override
  Future<void> createNewAccount() async {
    final ClientAccount account = await getAccountAndThrowIfNull();
    await remoteAccountDataSource.createAccountRequest(CreateAccountRequest(
      username: account.username,
      passwordHash: account.passwordHash,
      createAccountToken: appConfig.createAccountToken,
      encryptedDataKey: account.encryptedDataKey,
    ));
  }

  @override
  Future<ClientAccount> login() async {
    final ClientAccount account = await getAccountAndThrowIfNull();
    final AccountLoginResponse response = await remoteAccountDataSource.loginRequest(AccountLoginRequest(
      username: account.username,
      passwordHash: account.passwordHash,
      createAccountToken: appConfig.createAccountToken,
    ));
    account.sessionToken = response.sessionToken;
    account.encryptedDataKey = response.encryptedDataKey;
    return account;
  }

  @override
  Future<ClientAccount> updatePasswordOnServer(
      {required String newPasswordHash, required String newEncryptedDataKey}) async {
    final ClientAccount account = await getAccountAndThrowIfNull();
    final AccountChangePasswordRequest request = AccountChangePasswordRequest(
      newPasswordHash: newPasswordHash,
      newEncryptedDataKey: newEncryptedDataKey,
    );
    final AccountChangePasswordResponse response = await remoteAccountDataSource.changePasswordRequest(request);
    // update session token and keys of account
    account.sessionToken = response.sessionToken;
    account.passwordHash = newPasswordHash;
    account.encryptedDataKey = newEncryptedDataKey;
    return account;
  }

  @override
  Future<List<NoteInfo>?> getOldNotesForAccount(String username) async {
    final Map<String, List<NoteInfo>> accounts = await localDataSource.getOldAccounts();
    return accounts[username];
  }

  @override
  Future<void> saveNotesForOldAccount(String username, List<NoteInfo> notes) async {
    final Map<String, List<NoteInfo>> accounts = await localDataSource.getOldAccounts();
    accounts[username] = notes;
    await localDataSource.saveOldAccounts(accounts);
  }
}
