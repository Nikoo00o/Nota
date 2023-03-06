import 'package:app/presentation/widgets/base_pages/page_state.dart';

abstract class LoginState extends PageState {
  const LoginState() : super(const <String, Object?>{});
}

class LoginRemoteState extends LoginState {
  const LoginRemoteState();
}

class LoginLocalState extends LoginState {
  const LoginLocalState();
}

class LoginCreateState extends LoginState {
  const LoginCreateState();
}

