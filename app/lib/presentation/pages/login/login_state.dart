import 'package:app/presentation/widgets/base_pages/page_state.dart';

class LoginState extends PageState {
  const LoginState([super.properties = const <String, Object?>{}]);
}

class LoginRemoteState extends LoginState {
  const LoginRemoteState();
}

class LoginLocalState extends LoginState {
  final String username;

  LoginLocalState({required this.username})
      : super(<String, Object?>{
          "username": username,
        });
}

class LoginCreateState extends LoginState {
  const LoginCreateState();
}
