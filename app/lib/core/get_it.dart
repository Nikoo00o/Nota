import 'package:app/core/config/app_config.dart';
import 'package:app/data/datasources/file_picker_data_source.dart.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/local_data_source_impl.dart';
import 'package:app/data/datasources/remote_account_data_source.dart';
import 'package:app/data/datasources/remote_note_data_source.dart';
import 'package:app/data/repositories/account_repository_impl.dart';
import 'package:app/data/repositories/app_settings_repository_impl.dart';
import 'package:app/data/repositories/biometrics_repository_impl.dart';
import 'package:app/data/repositories/external_file_repository_impl.dart';
import 'package:app/data/repositories/note_structure_repository_impl.dart';
import 'package:app/data/repositories/note_transfer_repository_impl.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/repositories/biometrics_repository.dart';
import 'package:app/domain/repositories/external_file_repository.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/change/activate_lock_screen.dart';
import 'package:app/domain/usecases/account/change/change_account_password.dart';
import 'package:app/domain/usecases/account/change/change_auto_login.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/domain/usecases/account/get_auto_login.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/account/get_user_name.dart';
import 'package:app/domain/usecases/account/inner/fetch_current_session_token.dart';
import 'package:app/domain/usecases/account/login/can_login_with_biometrics.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/get_required_login_status.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:app/domain/usecases/account/save_account.dart';
import 'package:app/domain/usecases/favourites/change_favourite.dart';
import 'package:app/domain/usecases/favourites/get_favourites.dart';
import 'package:app/domain/usecases/favourites/is_favourite.dart';
import 'package:app/domain/usecases/favourites/update_favourite.dart';
import 'package:app/domain/usecases/note_structure/change_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/create_structure_item.dart';
import 'package:app/domain/usecases/note_structure/delete_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/export_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/finish_move_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/add_new_structure_update_batch.dart';
import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_structure/load_all_structure_content.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_current_structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_folders.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/domain/usecases/note_structure/start_move_structure_item.dart';
import 'package:app/domain/usecases/note_transfer/get_last_note_transfer_time.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:app/domain/usecases/note_transfer/load_note_buffer.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/domain/usecases/note_transfer/save_note_buffer.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:app/presentation/main/app/app_bloc.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/main/menu/menu_bloc.dart';
import 'package:app/presentation/pages/login/login_bloc.dart';
import 'package:app/presentation/pages/logs/logs_bloc.dart';
import 'package:app/presentation/pages/note_edit/note_edit_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/settings/settings_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:app/services/session_service.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/usecases/shared_fetch_current_session_token.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// Returns the GetIt service locator / singleton instance
final GetIt sl = GetIt.instance;

/// Alias for [sl]
GetIt get getIt => sl;

/// Initializes all singletons (also the lazy ones).
///
/// Some registrations are done with the abstract type instead of the implementation type, like for example:
/// [SharedFetchCurrentSessionToken] for [FetchCurrentSessionToken] and [AccountRepository] for [AccountRepositoryImpl].
///
/// You should always initialize the logger before!!! The next call after this should be: [LocalDataSource.init]
Future<void> initializeGetIt() async {
  // core elements
  sl.registerLazySingleton<AppConfig>(() => AppConfig());

  // data layer (data sources + repositories)
  sl.registerLazySingleton<RestClient>(
      () => RestClient(sharedConfig: _config(), fetchSessionTokenCallback: fetchCurrentSessionToken));

  sl.registerLazySingleton<LocalDataSource>(
      () => LocalDataSourceImpl(secureStorage: const FlutterSecureStorage(), appConfig: sl()));

  sl.registerLazySingleton<RemoteAccountDataSource>(() => RemoteAccountDataSourceImpl(restClient: sl()));
  sl.registerLazySingleton<RemoteNoteDataSource>(() => RemoteNoteDataSourceImpl(restClient: sl()));
  sl.registerLazySingleton<FilePickerDataSource>(() => FilePickerDataSourceImpl());

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
  sl.registerLazySingleton<AppSettingsRepository>(
      () => AppSettingsRepositoryImpl(localDataSource: sl(), appConfig: sl(), biometricsRepository: sl()));
  sl.registerLazySingleton<BiometricsRepository>(() => BiometricsRepositoryImpl(
        localDataSource: sl(),
        appConfig: sl(),
        dialogService: sl(),
      ));
  sl.registerLazySingleton<NoteStructureRepository>(() => NoteStructureRepositoryImpl(localDataSource: sl()));
  sl.registerLazySingleton<ExternalFileRepository>(() => ExternalFileRepositoryImpl(filePickerDataSource: sl()));

  // domain layer (use cases)
  sl.registerLazySingleton<SharedFetchCurrentSessionToken>(
      () => FetchCurrentSessionToken(accountRepository: sl(), appConfig: sl()));
  sl.registerLazySingleton<CreateAccount>(() => CreateAccount(accountRepository: sl(), appConfig: sl()));
  sl.registerLazySingleton<GetRequiredLoginStatus>(() => GetRequiredLoginStatus(accountRepository: sl()));
  sl.registerLazySingleton<CanLoginWithBiometrics>(() => CanLoginWithBiometrics(biometricsRepository: sl()));
  sl.registerLazySingleton<LoginToAccount>(() => LoginToAccount(
        accountRepository: sl(),
        appConfig: sl(),
        getRequiredLoginStatus: sl(),
        transferNotes: sl(),
        biometricsRepository: sl(),
      ));
  sl.registerLazySingleton<LogoutOfAccount>(() => LogoutOfAccount(
        accountRepository: sl(),
        appSettingsRepository: sl(),
        navigationService: sl(),
        appConfig: sl(),
        dialogService: sl(),
        noteStructureRepository: sl(),
      ));
  sl.registerLazySingleton<ChangeAccountPassword>(() => ChangeAccountPassword(
        accountRepository: sl(),
        appConfig: sl(),
        getLoggedInAccount: sl(),
        biometricsRepository: sl(),
      ));
  sl.registerLazySingleton<GetAutoLogin>(() => GetAutoLogin(accountRepository: sl()));
  sl.registerLazySingleton<ChangeAutoLogin>(() => ChangeAutoLogin(accountRepository: sl()));
  sl.registerLazySingleton<GetLoggedInAccount>(() => GetLoggedInAccount(accountRepository: sl()));
  sl.registerLazySingleton<GetUsername>(() => GetUsername(accountRepository: sl()));
  sl.registerLazySingleton<SaveAccount>(() => SaveAccount(accountRepository: sl()));
  sl.registerLazySingleton<ActivateLockscreen>(
      () => ActivateLockscreen(accountRepository: sl(), navigationService: sl()));

  sl.registerLazySingleton<LoadNoteContent>(
      () => LoadNoteContent(getLoggedInAccount: sl(), noteTransferRepository: sl()));
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
        fetchNewNoteStructure: sl(),
        updateFavourite: sl(),
      ));

  sl.registerLazySingleton<FetchNewNoteStructure>(() => FetchNewNoteStructure(
        noteStructureRepository: sl(),
        updateNoteStructure: sl(),
        getLoggedInAccount: sl(),
        appConfig: sl(),
      ));
  sl.registerLazySingleton<UpdateNoteStructure>(() => UpdateNoteStructure(
        noteStructureRepository: sl(),
        addNewStructureUpdateBatch: sl(),
      ));
  sl.registerLazySingleton<GetOriginalStructureItem>(() => GetOriginalStructureItem(
        noteStructureRepository: sl(),
        fetchNewNoteStructure: sl(),
      ));
  sl.registerLazySingleton<GetCurrentStructureItem>(() => GetCurrentStructureItem(
        noteStructureRepository: sl(),
        fetchNewNoteStructure: sl(),
      ));
  sl.registerLazySingleton<GetStructureFolders>(() => GetStructureFolders(
        noteStructureRepository: sl(),
        fetchNewNoteStructure: sl(),
      ));
  sl.registerLazySingleton<GetStructureUpdatesStream>(() => GetStructureUpdatesStream(
        noteStructureRepository: sl(),
      ));
  sl.registerLazySingleton<AddNewStructureUpdateBatch>(() => AddNewStructureUpdateBatch(
        noteStructureRepository: sl(),
      ));

  sl.registerLazySingleton<ChangeCurrentStructureItem>(() => ChangeCurrentStructureItem(
        noteStructureRepository: sl(),
        getOriginalStructureItem: sl(),
        updateNoteStructure: sl(),
        storeNoteEncrypted: sl(),
      ));
  sl.registerLazySingleton<DeleteCurrentStructureItem>(() => DeleteCurrentStructureItem(
        getOriginalStructureItem: sl(),
        updateNoteStructure: sl(),
        storeNoteEncrypted: sl(),
      ));
  sl.registerLazySingleton<CreateStructureItem>(() => CreateStructureItem(
        noteStructureRepository: sl(),
        getOriginalStructureItem: sl(),
        updateNoteStructure: sl(),
        storeNoteEncrypted: sl(),
        appConfig: sl(),
        externalFileRepository: sl(),
      ));
  sl.registerLazySingleton<StartMoveStructureItem>(() => StartMoveStructureItem(
        noteStructureRepository: sl(),
        getCurrentStructureItem: sl(),
        addNewStructureUpdateBatch: sl(),
      ));
  sl.registerLazySingleton<FinishMoveStructureItem>(() => FinishMoveStructureItem(
        noteStructureRepository: sl(),
        getOriginalStructureItem: sl(),
        updateNoteStructure: sl(),
        getCurrentStructureItem: sl(),
        storeNoteEncrypted: sl(),
      ));
  sl.registerLazySingleton<NavigateToItem>(() => NavigateToItem(
        noteStructureRepository: sl(),
        fetchNewNoteStructure: sl(),
        addNewStructureUpdateBatch: sl(),
      ));
  sl.registerLazySingleton<LoadNoteBuffer>(() => LoadNoteBuffer(
        noteTransferRepository: sl(),
        getLoggedInAccount: sl(),
      ));
  sl.registerLazySingleton<SaveNoteBuffer>(() => SaveNoteBuffer(
        noteTransferRepository: sl(),
        getLoggedInAccount: sl(),
      ));
  sl.registerLazySingleton<LoadAllStructureContent>(() => LoadAllStructureContent(
        noteStructureRepository: sl(),
        loadNoteContent: sl(),
        appConfig: sl(),
      ));
  sl.registerLazySingleton<GetLastNoteTransferTime>(() => GetLastNoteTransferTime(
        localDataSource: sl(),
      ));
  sl.registerLazySingleton<ChangeFavourite>(() => ChangeFavourite(
        appSettingsRepository: sl(),
      ));
  sl.registerLazySingleton<GetFavourites>(() => GetFavourites(
        appSettingsRepository: sl(),
        noteStructureRepository: sl(),
        fetchNewNoteStructure: sl(),
      ));
  sl.registerLazySingleton<IsFavourite>(() => IsFavourite(
        appSettingsRepository: sl(),
      ));
  sl.registerLazySingleton<UpdateFavourite>(() => UpdateFavourite(
        appSettingsRepository: sl(),
        isFavourite: sl(),
      ));
  sl.registerLazySingleton<ExportCurrentStructureItem>(() => ExportCurrentStructureItem(
        externalFileRepository: sl(),
        getOriginalStructureItem: sl(),
        loadNoteContent: sl(),
        translationService: sl(),
      ));

  // services
  sl.registerLazySingleton<SessionService>(() => SessionService());
  sl.registerLazySingleton<DialogService>(() => DialogServiceImpl());
  sl.registerLazySingleton<NavigationService>(() => NavigationService());
  sl.registerLazySingleton<TranslationService>(() => TranslationService(appSettingsRepository: sl()));

  // presentation layer (blocs)
  sl.registerFactory<AppBloc>(() => AppBloc(translationService: sl(), appSettingsRepository: sl()));
  sl.registerFactory<DialogOverlayBloc>(() => DialogOverlayBloc(
        dialogOverlayKey: GlobalKey(),
        translationService: sl(),
        dialogService: sl(),
      ));
  // the blocs below are factory functions, because they should be newly created each time the user navigates to the page!
  sl.registerFactory<LoginBloc>(() => LoginBloc(
        navigationService: sl(),
        dialogService: sl(),
        getRequiredLoginStatus: sl(),
        getUsername: sl(),
        createAccount: sl(),
        loginToAccount: sl(),
        logoutOfAccount: sl(),
        canLoginWithBiometrics: sl(),
      ));
  sl.registerFactory<NoteSelectionBloc>(() => NoteSelectionBloc(
        getCurrentStructureItem: sl(),
        appConfig: sl(),
        getStructureUpdatesStream: sl(),
        navigationService: sl(),
        createStructureItem: sl(),
        startMoveStructureItem: sl(),
        deleteCurrentStructureItem: sl(),
        changeCurrentStructureItem: sl(),
        transferNotes: sl(),
        getLastNoteTransferTime: sl(),
        loadAllStructureContent: sl(),
        finishMoveStructureItem: sl(),
        navigateToItem: sl(),
        dialogService: sl(),
        isFavourite: sl(),
        changeFavourite: sl(),
      ));
  sl.registerFactory<NoteEditBloc>(() => NoteEditBloc(
        getCurrentStructureItem: sl(),
        getStructureUpdatesStream: sl(),
        navigationService: sl(),
        navigateToItem: sl(),
        changeCurrentStructureItem: sl(),
        loadNoteContent: sl(),
        dialogService: sl(),
        deleteCurrentStructureItem: sl(),
        startMoveStructureItem: sl(),
        loadNoteBuffer: sl(),
        saveNoteBuffer: sl(),
        appSettingsRepository: sl(),
        isFavourite: sl(),
        changeFavourite: sl(),
        appConfig: sl(),
      ));
  sl.registerFactory<SettingsBloc>(() => SettingsBloc(
        appSettingsRepository: sl(),
        changeAutoLogin: sl(),
        getAutoLogin: sl(),
        navigationService: sl(),
        changeAccountPassword: sl(),
        dialogService: sl(),
        biometricsRepository: sl(),
      ));
  sl.registerFactory<MenuBloc>(() => MenuBloc(
        getUsername: sl(),
        getStructureFolders: sl(),
        navigationService: sl(),
        changeAutoLogin: sl(),
        appConfig: sl(),
        logoutOfAccount: sl(),
        activateLockscreen: sl(),
        dialogService: sl(),
        navigateToItem: sl(),
        getFavourites: sl(),
      ));
  sl.registerFactory<LogsBloc>(() => LogsBloc(
        appSettingsRepository: sl(),
        navigationService: sl(),
        dialogService: sl(),
        appConfig: sl(),
      ));
}

Future<SessionToken?> fetchCurrentSessionToken() => sl<SharedFetchCurrentSessionToken>().call(const NoParams());

AppConfig _config() => sl<AppConfig>();
