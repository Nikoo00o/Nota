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

  // controllers are only used for clearing. also used inside of the ui to save the input
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final GlobalKey firstButtonScrollKey = GlobalKey();

  StreamSubscription<bool>? keyboardSubscription;

  LoginBloc({
    required this.getRequiredLoginStatus,
    required this.getUsername,
    required this.createAccount,
    required this.loginToAccount,
    required this.logoutOfAccount,
    required this.dialogService,
    required this.navigationService,
  }) : super(initialState: const LoginState());

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
      return;
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
    if (InputValidator.validateInput(username: usernameController.text, password: passwordController.text)) {
      await loginToAccount(LoginToAccountParamsRemote(
          username: usernameController.text, password: passwordController.text, reuseOldNotes: true));
      _navigateToNextPage();
    }
  }

  Future<void> _handleLocalLogin(LoginEventLocalLogin event, Emitter<LoginState> emit) async {
    if (InputValidator.validateInput(password: passwordController.text)) {
      await loginToAccount(LoginToAccountParamsLocal(password: passwordController.text));
      _navigateToNextPage();
    }
  }

  Future<void> _handleCreate(LoginEventCreate event, Emitter<LoginState> emit) async {
    if (InputValidator.validateInput(
      username: usernameController.text,
      password: passwordController.text,
      confirmPassword: passwordConfirmController.text,
    )) {
      if (InputValidator.validatePassword(passwordController.text) == false) {
        dialogService.showErrorDialog(const ShowErrorDialog(descriptionKey: "page.login.insecure.password"));
      } else if (passwordController.text != passwordConfirmController.text) {
        dialogService.showErrorDialog(const ShowErrorDialog(descriptionKey: "page.login.no.password.match"));
      } else {
        await createAccount(CreateAccountParams(username: usernameController.text, password: passwordController.text));
        dialogService.show(ShowInfoDialog(
          titleKey: "page.login.account.created.title",
          descriptionKey: "page.login.account.created.description",
          descriptionKeyParams: <String>[usernameController.text],
        ));
        _createNewAccount = false;
        add(const LoginEventInitialise());
      }
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
      return const LoginCreateState();
    }
    if (_loginStatus == RequiredLoginStatus.REMOTE) {
      return const LoginRemoteState();
    }
    return LoginLocalState(username: username ?? "");
  }

  void _navigateToNextPage() {
    _clearTextInputFields();
    navigationService.navigateTo(Routes.note_selection);
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
              firstButtonScrollKey.currentContext!,
              duration: const Duration(milliseconds: 250), // duration for scrolling time
              curve: Curves.easeInOutCubic,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
            );
          });
        }
      });
    }
  }
}
