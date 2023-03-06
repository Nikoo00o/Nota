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

class LoginPageBloc extends PageBloc<LoginPageEvent, LoginPageState> {
  final GetRequiredLoginStatus getRequiredLoginStatus;
  final CreateAccount createAccount;
  final LoginToAccount loginToAccount;
  final LogoutOfAccount logoutOfAccount;
  final DialogService dialogService;
  final NavigationService navigationService;
  late RequiredLoginStatus loginStatus;

  LoginPageBloc({
    required this.getRequiredLoginStatus,
    required this.createAccount,
    required this.loginToAccount,
    required this.logoutOfAccount,
    required this.dialogService,
    required this.navigationService,
  }) : super(initialState: LoginPageState(null));

  @override
  void registerEventHandlers() {
    on<LoginPageEventInitialise>(_handleInitialise);
    on<LoginPageEventRemoteLogin>(_handleRemoteLogin);
    on<LoginPageEventLocalLogin>(_handleLocalLogin);
    on<LoginPageEventCreate>(_handleCreate);
    on<LoginPageEventChangeAccount>(_handleChangeAccount);
  }

  Future<void> _handleInitialise(LoginPageEventInitialise event, Emitter<LoginPageState> emit) async {
    loginStatus = await getRequiredLoginStatus(const NoParams());
    if (loginStatus == RequiredLoginStatus.NONE) {
      _navigateToNextPage();
    }
    emit(LoginPageState(loginStatus));
  }

  Future<void> _handleRemoteLogin(LoginPageEventRemoteLogin event, Emitter<LoginPageState> emit) async {
    if (_validateInput(password: event.password, username: event.username)) {
      await loginToAccount(LoginToAccountParamsRemote(password: event.password, username: event.username));
      _navigateToNextPage();
    }
  }

  Future<void> _handleLocalLogin(LoginPageEventLocalLogin event, Emitter<LoginPageState> emit) async {
    if (_validateInput(password: event.password)) {
      await loginToAccount(LoginToAccountParamsLocal(password: event.password));
      _navigateToNextPage();
    }
  }

  Future<void> _handleCreate(LoginPageEventCreate event, Emitter<LoginPageState> emit) async {
    if (_validateInput(password: event.password, username: event.username)) {
      await createAccount(CreateAccountParams(username: event.username, password: event.password));
      dialogService.showInfoDialog("page.login.account.created");
    }
  }

  Future<void> _handleChangeAccount(LoginPageEventChangeAccount event, Emitter<LoginPageState> emit) async {
    await logoutOfAccount(const LogoutOfAccountParams(navigateToLoginPage: false));
    add(const LoginPageEventInitialise());
  }

  void _navigateToNextPage() {
    navigationService.navigateTo(Routes.notes);
  }

  /// Returns if the input was valid
  bool _validateInput({String? username, required String password}) {
    if (username?.isNotEmpty ?? true && password.isNotEmpty) {
      if(_checkPassword(password) == false){
        Logger.error("The password was not secure");
        dialogService.showErrorDialog("page.login.unsecure.password");
        return false;
      }
      return true;
    }
    Logger.error("The username, or password field was empty");
    dialogService.showErrorDialog("page.login.empty.params");
    return false;
  }

  /// The password should contain at least 4 characters and it should contain at least one lowercase letter, one uppercase
  /// letter and one number
  bool _checkPassword(String password) =>
      password.length >= 4 &&
      RegExp(r"[A-Z]").hasMatch(password) &&
      RegExp(r"[a-z]").hasMatch(password) &&
      RegExp(r"\d").hasMatch(password);
}
