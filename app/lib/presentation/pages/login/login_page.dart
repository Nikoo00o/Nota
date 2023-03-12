import 'package:app/core/get_it.dart';
import 'package:app/presentation/pages/login/login_bloc.dart';
import 'package:app/presentation/pages/login/login_bloc_arguments.dart';
import 'package:app/presentation/pages/login/login_event.dart';
import 'package:app/presentation/pages/login/login_state.dart';
import 'package:app/presentation/pages/login/widgets/login_buttons.dart';
import 'package:app/presentation/pages/login/widgets/login_description.dart';
import 'package:app/presentation/pages/login/widgets/login_inputs.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends BlocPage<LoginBloc, LoginState> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  LoginPage() : super();

  @override
  LoginBloc createBloc(BuildContext context) {
    final LoginBloc bloc = sl<LoginBloc>(param1: LoginBlocArguments(firstButtonScrollKey: GlobalKey()));
    bloc.usernameController = usernameController;
    bloc.passwordController = passwordController;
    bloc.passwordConfirmController = passwordConfirmController;
    bloc.scrollController = scrollController;
    return bloc..add(const LoginEventInitialise());
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Center(
      child: Scrollbar(
        scrollbarOrientation: ScrollbarOrientation.right,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(40, 5, 40, 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const LoginDescription(),
              const SizedBox(height: 25),
              LoginInputs(
                usernameController: usernameController,
                passwordController: passwordController,
                passwordConfirmController: passwordConfirmController,
              ),
              const SizedBox(height: 25),
              LoginButtons(
                usernameController: usernameController,
                passwordController: passwordController,
                passwordConfirmController: passwordConfirmController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) => createAppBarWithState(context);

  @override
  PreferredSizeWidget buildAppBarWithState(BuildContext context, LoginState state) {
    return AppBar(centerTitle: false, title: Text(translate(context, _getPageTitle(state))));
  }

  String _getPageTitle(LoginState state) {
    if (state is LoginCreateState) {
      return "page.login.title.create";
    }
    if (state is LoginRemoteState) {
      return "page.login.title.remote.login";
    }
    if (state is LoginLocalState) {
      return "page.login.title.local.login";
    }
    return "empty";
  }

  @override
  String get pageName => "login";
}
