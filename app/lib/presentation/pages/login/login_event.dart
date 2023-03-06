import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class LoginPageEvent extends PageEvent {
  const LoginPageEvent();
}

class LoginPageEventInitialise extends LoginPageEvent {
  const LoginPageEventInitialise();
}

class LoginPageEventRemoteLogin extends LoginPageEvent {
  final String username;
  final String password;

  const LoginPageEventRemoteLogin(this.username, this.password);
}

class LoginPageEventLocalLogin extends LoginPageEvent {
  final String password;

  const LoginPageEventLocalLogin(this.password);
}

class LoginPageEventCreate extends LoginPageEvent {
  final String username;
  final String password;
  final String confirmPassword;

  const LoginPageEventCreate({required this.username, required this.password, required this.confirmPassword});
}

/// Switch from local to remote login.
class LoginPageEventChangeAccount extends LoginPageEvent {
  const LoginPageEventChangeAccount();
}

/// Switch from login to create account, or back.
class LoginPageEventSwitchCreation extends LoginPageEvent {
  final bool isCreateAccount;

  const LoginPageEventSwitchCreation({required this.isCreateAccount});
}
