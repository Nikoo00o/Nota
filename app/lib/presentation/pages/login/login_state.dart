import 'package:app/presentation/widgets/base_pages/page_state.dart';

base class LoginState extends PageState {
  const LoginState([super.properties = const <String, Object?>{}]);
}

final class LoginRemoteState extends LoginState {
  const LoginRemoteState();
}

final class LoginLocalState extends LoginState {
  final String username;

  LoginLocalState({required this.username})
      : super(<String, Object?>{
          "username": username,
        });
}

final class LoginCreateState extends LoginState {
  const LoginCreateState();
}

final class LoginErrorState extends LoginState {
  final String dataFolderPath;
  const LoginErrorState({required this.dataFolderPath});
}