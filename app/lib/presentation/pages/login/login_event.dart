import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class LoginEvent extends PageEvent {
  const LoginEvent();
}

class LoginEventInitialise extends LoginEvent {
  const LoginEventInitialise();
}

class LoginEventRemoteLogin extends LoginEvent {
  const LoginEventRemoteLogin();
}

class LoginEventLocalLogin extends LoginEvent {
  const LoginEventLocalLogin();
}

class LoginEventCreate extends LoginEvent {
  const LoginEventCreate();
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
