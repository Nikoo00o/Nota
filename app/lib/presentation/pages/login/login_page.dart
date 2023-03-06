import 'package:app/core/enums/required_login_status.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/pages/login/login_bloc.dart';
import 'package:app/presentation/pages/login/login_event.dart';
import 'package:app/presentation/pages/login/login_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends BlocPage<LoginPageBloc, LoginPageState> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  LoginPageBloc createBloc(BuildContext context) {
    return sl<LoginPageBloc>()..add(const LoginPageEventInitialise());
  }

  @override
  Widget buildPartWithNoState(BuildContext context, Widget partWithState) {
    // todo: add menu!
    return Scaffold(
      body: SingleChildScrollView(child: partWithState),
    );
  }

  @override
  Widget buildPartWithState(BuildContext context, LoginPageState state) {
    if (state.loginStatus == null) {
      return const SizedBox();
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildInput(context, state),
        const SizedBox(height: 30),
        _buildButtons(context, state),
      ],
    );
  }

  Widget _buildInput(BuildContext context, LoginPageState state) {
    final bool hasUsername = state.loginStatus == RequiredLoginStatus.REMOTE;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        if (hasUsername)
          TextField(
            controller: usernameController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: translate("page.login.user"),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        if (hasUsername) const SizedBox(height: 25),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: translate("page.login.password"),
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, LoginPageState state) {
    final bool isRemote = state.loginStatus == RequiredLoginStatus.REMOTE;
    final String button2Key = isRemote ? "page.login.create" : "page.login.change";
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        FilledButton(
          onPressed: () {
            if (isRemote) {
              currentBloc(context).add(LoginPageEventRemoteLogin(usernameController.text, passwordController.text));
            } else {
              currentBloc(context).add(LoginPageEventLocalLogin(passwordController.text));
            }
          },
          child: Text(translate("page.login.login")),
        ),
        const SizedBox(height: 5),
        FilledButton(
          onPressed: () {
            if (isRemote) {
              currentBloc(context).add(LoginPageEventCreate(usernameController.text, passwordController.text));
            } else {
              currentBloc(context).add(const LoginPageEventChangeAccount());
            }
          },
          child: Text(translate(button2Key)),
        ),
      ],
    );
  }

  @override
  String get pageName => "login";
}
