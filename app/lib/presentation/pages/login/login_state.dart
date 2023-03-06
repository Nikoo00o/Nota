import 'package:app/core/enums/required_login_status.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';

abstract class LoginPageState extends PageState {
  const LoginPageState() : super(const <String, Object?>{});
}

class LoginPageRemoteState extends LoginPageState {
  const LoginPageRemoteState();
}

class LoginPageLocalState extends LoginPageState {
  const LoginPageLocalState();
}

class LoginPageCreateState extends LoginPageState {
  const LoginPageCreateState();
}

