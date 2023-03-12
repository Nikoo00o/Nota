import 'package:app/core/config/app_config.dart';
import 'package:app/core/constants/routes.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/domain/usecases/account/change/activate_lock_screen.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/domain/usecases/account/get_user_name.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_folders.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/presentation/main/menu/menu_event.dart';
import 'package:app/presentation/main/menu/menu_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/usecases/usecase.dart';

class MenuBloc extends PageBloc<MenuEvent, MenuState> {
  final GetUsername getUsername;

  // todo: currently the menu is recreated each time it is opened, so it does not need streamed changes. in the future it
  //  might also need the use case [GetStructureUpdatesStream]
  final GetStructureFolders getStructureFolders;
  final NavigateToItem navigateToItem;
  final NavigationService navigationService;
  final DialogService dialogService;
  final ActivateLockscreen activateLockscreen;
  final LogoutOfAccount logoutOfAccount;
  final AppConfig appConfig;
  late String? userName;

  /// the current page of the user which should be highlighted inside of the menu
  late String currentPageTranslationKey;

  /// This will only be not null for user menu entries which will not be translated.
  /// For those the [currentPageTranslationKey] will be: "empty.param.1"!
  List<String>? currentPageTranslationKeyParams;

  /// The menu items for the notes to click on
  late Map<TranslationString, StructureFolder> noteFolders;

  /// The menu needs its own scroll controller
  final ScrollController scrollController = ScrollController();

  MenuBloc({
    required this.getUsername,
    required this.getStructureFolders,
    required this.navigateToItem,
    required this.navigationService,
    required this.dialogService,
    required this.appConfig,
    required this.activateLockscreen,
    required this.logoutOfAccount,
  }) : super(initialState: const MenuState());

  @override
  void registerEventHandlers() {
    on<MenuInitialised>(_handleInitialise);
    on<MenuItemClicked>(_handleMenuItemClicked);
  }

  Future<void> _handleInitialise(MenuInitialised event, Emitter<MenuState> emit) async {
    userName = await getUsername(const NoParams());
    currentPageTranslationKey = event.currentPageTranslationKey;
    currentPageTranslationKeyParams = event.currentPageTranslationKeyParams;
    noteFolders = await getStructureFolders.call(const GetStructureFoldersParams(includeMoveFolder: false));
    emit(_buildState());
  }

  Future<void> _handleMenuItemClicked(MenuItemClicked event, Emitter<MenuState> emit) async {
    currentPageTranslationKey = event.targetPageTranslationKey;
    currentPageTranslationKeyParams = event.targetPageTranslationKeyParams;

    // todo: handle all actions for every menu item. same as in menu_item.dart!
    switch (currentPageTranslationKey) {
      case "empty.param.1":
        await _userMenuEntryClicked();
        break;

      case "menu.lock.screen.title":
        await activateLockscreen(const NoParams());
        break;
      case "menu.logout.title":
        await logoutOfAccount(const LogoutOfAccountParams(navigateToLoginPage: true));
        break;
      case "page.settings.title":
        navigationService.navigateTo(Routes.settings);
        break;
      case "menu.about":
        dialogService.showAboutDialog();
        break;

      case "page.dialog.test.title":
        navigationService.navigateTo(Routes.dialog_test);
        break;
      case "page.material.color.test.title":
        navigationService.navigateTo(Routes.material_color_test);
        break;
      case "page.splash.screen.test.title":
        navigationService.navigateTo(Routes.splash_screen_test);
        break;

      default:
        await _topLevelNoteFolderClicked();
    }

    emit(_buildState());
  }

  Future<void> _topLevelNoteFolderClicked() async {
    await navigateToItem.call(NavigateToItemParamsTopLevelName(folderName: currentPageTranslationKey));
    navigationService.navigateTo(Routes.notes);
  }

  Future<void> _userMenuEntryClicked() async {}

  MenuState _buildState() {
    return MenuStateInitialised(
      userName: userName,
      currentPageTranslationKey: currentPageTranslationKey,
      currentPageTranslationKeyParams: currentPageTranslationKeyParams,
      showDeveloperOptions: appConfig.showDeveloperOptions,
      topLevelFolders: noteFolders.keys.toList(),
    );
  }
}
