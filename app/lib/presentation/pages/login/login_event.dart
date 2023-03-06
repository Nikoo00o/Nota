import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class LoginEvent extends PageEvent {
  const LoginEvent();
}

class LoginEventInitialise extends LoginEvent {
  const LoginEventInitialise();
}

class LoginEventRemoteLogin extends LoginEvent {
  final String username;
  final String password;

  const LoginEventRemoteLogin(this.username, this.password);
}

class LoginEventLocalLogin extends LoginEvent {
  final String password;

  const LoginEventLocalLogin(this.password);
}

class LoginEventCreate extends LoginEvent {
  final String username;
  final String password;
  final String confirmPassword;

  const LoginEventCreate({required this.username, required this.password, required this.confirmPassword});
}

/// Switch from local to remote login.
class LoginEventChangeAccount extends LoginEvent {
  const LoginEventChangeAccount();
}

/// Switch from login to create account, or back.
class LoginEventSwitchCreation extends LoginEvent {
  final bool isCreateAccount;

  const LoginEventSwitchCreation({required this.isCreateAccount});
}
