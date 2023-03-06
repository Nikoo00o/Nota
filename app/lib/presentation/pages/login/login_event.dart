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

  const LoginPageEventCreate(this.username, this.password);
}

class LoginPageEventChangeAccount extends LoginPageEvent {
  const LoginPageEventChangeAccount();
}
