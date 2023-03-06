import 'package:app/core/constants/routes.dart';
import 'package:app/core/enums/required_login_status.dart';
import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/domain/usecases/account/login/create_account.dart';
import 'package:app/domain/usecases/account/login/get_required_login_status.dart';
import 'package:app/domain/usecases/account/login/login_to_account.dart';
import 'package:app/presentation/pages/login/login_event.dart';
import 'package:app/presentation/pages/login/login_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

class LoginBloc extends PageBloc<LoginEvent, LoginState> {
  final GetRequiredLoginStatus getRequiredLoginStatus;
  final CreateAccount createAccount;
  final LoginToAccount loginToAccount;
  final LogoutOfAccount logoutOfAccount;
  final DialogService dialogService;
  final NavigationService navigationService;

  late RequiredLoginStatus _loginStatus;
  bool _createNewAccount = false;

  LoginBloc({
    required this.getRequiredLoginStatus,
    required this.createAccount,
    required this.loginToAccount,
    required this.logoutOfAccount,
    required this.dialogService,
    required this.navigationService,
  }) : super(initialState: const LoginLocalState());

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
    emit(_buildState());
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
      dialogService.showInfoDialog("page.login.account.created");
    }
  }

  Future<void> _handleChangeAccount(LoginEventChangeAccount event, Emitter<LoginState> emit) async {
    await logoutOfAccount(const LogoutOfAccountParams(navigateToLoginPage: false));
    add(const LoginEventInitialise());
  }

  Future<void> _handleSwitchCreation(LoginEventSwitchCreation event, Emitter<LoginState> emit) async {
    _createNewAccount = event.isCreateAccount;
    emit(_buildState());
  }

  LoginState _buildState() {
    if (_createNewAccount) {
      return const LoginCreateState();
    }
    if (_loginStatus == RequiredLoginStatus.REMOTE) {
      return const LoginRemoteState();
    }
    return const LoginLocalState();
  }

  void _navigateToNextPage() {
    navigationService.navigateTo(Routes.notes);
  }

  bool _validateInput({String? username, required String password, String? confirmPassword}) {
    if ((username?.isNotEmpty ?? true) && password.isNotEmpty && (confirmPassword?.isNotEmpty ?? true)) {
      return true;
    }
    Logger.error("One of the login page input fields was empty");
    dialogService.showErrorDialog("page.login.empty.params");
    return false;
  }
}
