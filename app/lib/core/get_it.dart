import 'package:app/core/config/app_config.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/local_data_source_impl.dart';
import 'package:app/data/datasources/remote_account_data_source.dart';
import 'package:app/data/datasources/remote_note_data_source.dart';
import 'package:app/data/repositories/account_repository_impl.dart';
import 'package:app/data/repositories/app_settings_repository_impl.dart';
import 'package:app/data/repositories/note_structure_repository_impl.dart';
import 'package:app/data/repositories/note_transfer_repository_impl.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/change/change_account_password.dart';
import 'package:app/domain/usecases/account/change/change_auto_login.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/domain/usecases/account/inner/fetch_current_session_token.dart';
import 'package:app/domain/usecases/account/get_auto_login.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/get_required_login_status.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:app/domain/usecases/account/save_account.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_structure/get_structure_folders.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/session_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/usecases/shared_fetch_current_session_token.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

/// Initializes all singletons (also the lazy ones).
///
/// Some registrations are done with the abstract type instead of the implementation type, like for example:
/// [SharedFetchCurrentSessionToken] for [FetchCurrentSessionToken] and [AccountRepository] for [AccountRepositoryImpl].
///
/// You should always initialize the logger before!!! The next call after this should be: [LocalDataSource.init]
Future<void> initializeGetIt() async {
  sl.registerLazySingleton<AppConfig>(() => AppConfig());
  sl.registerLazySingleton<RestClient>(
      () => RestClient(sharedConfig: _config(), fetchSessionTokenCallback: fetchCurrentSessionToken));

  sl.registerLazySingleton<LocalDataSource>(
      () => LocalDataSourceImpl(secureStorage: const FlutterSecureStorage(), appConfig: sl()));

  sl.registerLazySingleton<RemoteAccountDataSource>(() => RemoteAccountDataSourceImpl(restClient: sl()));
  sl.registerLazySingleton<RemoteNoteDataSource>(() => RemoteNoteDataSourceImpl(restClient: sl()));

  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(
        remoteAccountDataSource: sl(),
        localDataSource: sl(),
        appConfig: sl(),
      ));
  sl.registerLazySingleton<NoteTransferRepository>(() => NoteTransferRepositoryImpl(
        remoteNoteDataSource: sl(),
        localDataSource: sl(),
        appConfig: sl(),
      ));
  sl.registerLazySingleton<AppSettingsRepository>(() => AppSettingsRepositoryImpl(localDataSource: sl(), appConfig: sl()));
  sl.registerLazySingleton<NoteStructureRepository>(() => NoteStructureRepositoryImpl(localDataSource: sl()));

  sl.registerLazySingleton<SharedFetchCurrentSessionToken>(
      () => FetchCurrentSessionToken(accountRepository: sl(), appConfig: sl()));
  sl.registerLazySingleton<CreateAccount>(() => CreateAccount(accountRepository: sl(), appConfig: sl()));
  sl.registerLazySingleton<GetRequiredLoginStatus>(() => GetRequiredLoginStatus(accountRepository: sl()));
  sl.registerLazySingleton<LoginToAccount>(() => LoginToAccount(
        accountRepository: sl(),
        appConfig: sl(),
        getRequiredLoginStatus: sl(),
      ));
  sl.registerLazySingleton<LogoutOfAccount>(() => LogoutOfAccount(accountRepository: sl(), appConfig: sl()));
  sl.registerLazySingleton<ChangeAccountPassword>(() => ChangeAccountPassword(
        accountRepository: sl(),
        appConfig: sl(),
        getLoggedInAccount: sl(),
      ));
  sl.registerLazySingleton<GetAutoLogin>(() => GetAutoLogin(accountRepository: sl()));
  sl.registerLazySingleton<ChangeAutoLogin>(() => ChangeAutoLogin(accountRepository: sl()));
  sl.registerLazySingleton<GetLoggedInAccount>(() => GetLoggedInAccount(accountRepository: sl()));
  sl.registerLazySingleton<SaveAccount>(() => SaveAccount(accountRepository: sl()));

  sl.registerLazySingleton<LoadNoteContent>(() => LoadNoteContent(getLoggedInAccount: sl(), noteTransferRepository: sl()));
  sl.registerLazySingleton<StoreNoteEncrypted>(() => StoreNoteEncrypted(
        getLoggedInAccount: sl(),
        noteTransferRepository: sl(),
        saveAccount: sl(),
      ));
  sl.registerLazySingleton<TransferNotes>(() => TransferNotes(
        getLoggedInAccount: sl(),
        noteTransferRepository: sl(),
        saveAccount: sl(),
        dialogService: sl(),
      ));

  sl.registerLazySingleton<FetchNewNoteStructure>(() => FetchNewNoteStructure(
        noteStructureRepository: sl(),
        updateNoteStructure: sl(),
        getLoggedInAccount: sl(),
      ));
  sl.registerLazySingleton<UpdateNoteStructure>(() => UpdateNoteStructure(noteStructureRepository: sl()));
  sl.registerLazySingleton<GetOriginalStructureItem>(() => GetOriginalStructureItem(
      noteStructureRepository: sl(),
      fetchNewNoteStructure: sl(),
  ));
  sl.registerLazySingleton<GetCurrentStructureItem>(() => GetCurrentStructureItem(
        noteStructureRepository: sl(),
        fetchNewNoteStructure: sl(),
      ));
  sl.registerLazySingleton<GetCurrentStructureFolders>(() => GetCurrentStructureFolders(
        noteStructureRepository: sl(),
        fetchNewNoteStructure: sl(),
      ));

  sl.registerLazySingleton<ChangeCurrentStructureItem>(() => ChangeCurrentStructureItem(
        noteStructureRepository: sl(),
        getOriginalStructureItem: sl(),
        updateNoteStructure: sl(),
        storeNoteEncrypted: sl(),
      ));

  sl.registerLazySingleton<SessionService>(() => SessionService());
  sl.registerLazySingleton<DialogService>(() => DialogService());
}

Future<SessionToken?> fetchCurrentSessionToken() => sl<SharedFetchCurrentSessionToken>().call(const NoParams());

AppConfig _config() => sl<AppConfig>();
