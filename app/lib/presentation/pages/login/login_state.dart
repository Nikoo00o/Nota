import 'package:app/core/enums/required_login_status.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';

class LoginPageState extends PageState {
  final RequiredLoginStatus? loginStatus;

  LoginPageState(this.loginStatus) : super(<String, Object?>{"loginStatus": loginStatus});
}
