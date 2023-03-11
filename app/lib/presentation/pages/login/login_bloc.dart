import 'dart:async';
import 'package:app/core/constants/routes.dart';
import 'package:app/core/enums/required_login_status.dart';
import 'package:app/core/utils/input_validator.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/domain/usecases/account/get_user_name.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/get_required_login_status.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/login/login_event.dart';
import 'package:app/presentation/pages/login/login_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

class LoginBloc extends PageBloc<LoginEvent, LoginState> {
  final GetRequiredLoginStatus getRequiredLoginStatus;
  final GetUsername getUsername;
  final CreateAccount createAccount;
  final LoginToAccount loginToAccount;
  final LogoutOfAccount logoutOfAccount;
  final DialogService dialogService;
  final NavigationService navigationService;

  late RequiredLoginStatus _loginStatus;
  bool _createNewAccount = false;

  // controllers are set by ui and only used for clearing
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController passwordConfirmController;
  late final ScrollController scrollController;

  StreamSubscription<bool>? keyboardSubscription;

  LoginBloc({
    required this.getRequiredLoginStatus,
    required this.getUsername,
    required this.createAccount,
    required this.loginToAccount,
    required this.logoutOfAccount,
    required this.dialogService,
    required this.navigationService,
    required GlobalKey firstButtonScrollKey,
  }) : super(initialState: LoginRemoteState(firstButtonScrollKey: firstButtonScrollKey));

  @override
  void registerEventHandlers() {
    on<LoginEventInitialise>(_handleInitialise);
    on<LoginEventRemoteLogin>(_handleRemoteLogin);
    on<LoginEventLocalLogin>(_handleLocalLogin);
    on<LoginEventCreate>(_handleCreate);
    on<LoginEventChangeAccount>(_handleChangeAccount);
    on<LoginEventSwitchCreation>(_handleSwitchCreation);
  }

  Future<void> _handleInitialise(LoginEventInitialise event, Emitter<LoginState> emit) async {
    _loginStatus = await getRequiredLoginStatus(const NoParams());
    if (_loginStatus == RequiredLoginStatus.NONE) {
      _navigateToNextPage();
    }
    _clearTextInputFields();
    _setupAutoScroll();
    String? username;
    if (_loginStatus == RequiredLoginStatus.LOCAL) {
      username = await getUsername.call(const NoParams());
    }
    emit(_buildState(username: username));
  }

  Future<void> _handleRemoteLogin(LoginEventRemoteLogin event, Emitter<LoginState> emit) async {
    if (_validateInput(password: event.password, username: event.username)) {
      await loginToAccount(LoginToAccountParamsRemote(password: event.password, username: event.username));
      _navigateToNextPage();
    }
  }

  Future<void> _handleLocalLogin(LoginEventLocalLogin event, Emitter<LoginState> emit) async {
    if (_validateInput(password: event.password)) {
      await loginToAccount(LoginToAccountParamsLocal(password: event.password));
      _navigateToNextPage();
    }
  }

  Future<void> _handleCreate(LoginEventCreate event, Emitter<LoginState> emit) async {
    if (_validateInput(password: event.password, username: event.username, confirmPassword: event.confirmPassword)) {
      await createAccount(CreateAccountParams(username: event.username, password: event.password));
      dialogService.show(ShowInfoDialog(
        titleKey: "page.login.account.created.title",
        descriptionKey: "page.login.account.created.description",
        descriptionKeyParams: <String>[event.username],
      ));
      _createNewAccount = false;
      add(const LoginEventInitialise());
    }
  }

  Future<void> _handleChangeAccount(LoginEventChangeAccount event, Emitter<LoginState> emit) async {
    await logoutOfAccount(const LogoutOfAccountParams(navigateToLoginPage: false));
    add(const LoginEventInitialise());
  }

  Future<void> _handleSwitchCreation(LoginEventSwitchCreation event, Emitter<LoginState> emit) async {
    _createNewAccount = event.isCreateAccount;
    add(const LoginEventInitialise());
  }

  /// [username] is only used for [LoginLocalState]
  LoginState _buildState({String? username}) {
    if (_createNewAccount) {
      // the global key will never change, because it is only created once and then always copied
      return LoginCreateState(firstButtonScrollKey: state.firstButtonScrollKey);
    }
    if (_loginStatus == RequiredLoginStatus.REMOTE) {
      return LoginRemoteState(firstButtonScrollKey: state.firstButtonScrollKey);
    }
    return LoginLocalState(firstButtonScrollKey: state.firstButtonScrollKey, username: username ?? "");
  }

  void _navigateToNextPage() {
    navigationService.navigateTo(Routes.notes);
  }

  /// returns false on error
  bool _validateInput({String? username, required String password, String? confirmPassword}) {
    final bool fieldsAreNotEmpty =
        (username?.isNotEmpty ?? true) && password.isNotEmpty && (confirmPassword?.isNotEmpty ?? true);
    if (fieldsAreNotEmpty == false) {
      Logger.error("One of the login page input fields was empty");
      dialogService.show(const ShowErrorDialog(descriptionKey: "page.login.empty.params"));
      return false;
    }
    if (InputValidator.validatePassword(password) == false) {
      Logger.error("The password was not secure enough");
      dialogService.show(const ShowErrorDialog(descriptionKey: "page.login.insecure.password"));
    }

    if (confirmPassword != null && password !=confirmPassword) {
      Logger.error("The passwords did not match");
      dialogService.show(const ShowErrorDialog(descriptionKey: "page.login.no.password.match"));
      return false;
    }
    return true;
  }

  void _clearTextInputFields() {
    usernameController.clear();
    passwordController.clear();
    passwordConfirmController.clear();
  }

  @mustCallSuper
  @override
  Future<void> close() async {
    // override close to cleanup subscription
    await keyboardSubscription?.cancel();
    keyboardSubscription = null;
    return super.close();
  }

  /// Creates the callback to automatically scroll to the first button when the keyboard opens
  void _setupAutoScroll() {
    if (keyboardSubscription == null) {
      final KeyboardVisibilityController keyboardVisibilityController = KeyboardVisibilityController();
      keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
        if (visible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Scrollable.ensureVisible(
              state.firstButtonScrollKey.currentContext!,
              duration: const Duration(milliseconds: 250), // duration for scrolling time
              curve: Curves.easeInOutCubic,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
            );
            //scrollController.jumpTo(value)
          });
        }
      });
    }
  }
}
