import 'package:app/presentation/widgets/base_pages/page_event.dart';

sealed class LoginEvent extends PageEvent {
  const LoginEvent();
}

final class LoginEventInitialise extends LoginEvent {
  const LoginEventInitialise();
}

final class LoginEventRemoteLogin extends LoginEvent {
  const LoginEventRemoteLogin();
}

final class LoginEventLocalLogin extends LoginEvent {
  const LoginEventLocalLogin();
}

final class LoginEventCreate extends LoginEvent {
  const LoginEventCreate();
}

/// Switch from local to remote login.
final class LoginEventChangeAccount extends LoginEvent {
  const LoginEventChangeAccount();
}

/// Switch from login to create account, or back.
final class LoginEventSwitchCreation extends LoginEvent {
  final bool isCreateAccount;

  const LoginEventSwitchCreation({required this.isCreateAccount});
}
