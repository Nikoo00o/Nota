import 'package:app/core/get_it.dart';
import 'package:app/presentation/pages/login/login_bloc.dart';
import 'package:app/presentation/pages/login/login_event.dart';
import 'package:app/presentation/pages/login/login_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends BlocPage<LoginPageBloc, LoginPageState> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();

  LoginPage() : super(pagePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0));

  @override
  LoginPageBloc createBloc(BuildContext context) {
    return sl<LoginPageBloc>()..add(const LoginPageEventInitialise());
  }

  @override
  Widget buildPartWithNoState(BuildContext context, Widget partWithState) {
    // todo: add menu inside of the scaffold and also add app bar ! maybe add a icon here as well
    return Scaffold(
      body: SingleChildScrollView(child: partWithState),
    );
  }

  @override
  Widget buildPartWithState(BuildContext context, LoginPageState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildInput(context, state),
        const SizedBox(height: 20),
        _buildButtons(context, state),
      ],
    );
  }

  Widget _buildInput(BuildContext context, LoginPageState state) {
    const double space = 15; //height between fields
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        if (state is LoginPageRemoteState || state is LoginPageCreateState)
          TextFormField(
            controller: usernameController,
            validator: _usernameValidator,
            decoration: InputDecoration(
              labelText: translate("page.login.name"),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        if (state is LoginPageRemoteState || state is LoginPageCreateState) const SizedBox(height: space),
        TextFormField(
          controller: passwordController,
          validator: _passwordValidator,
          obscureText: true,
          decoration: InputDecoration(
            labelText: translate("page.login.password"),
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
        if (state is LoginPageCreateState) const SizedBox(height: space),
        if (state is LoginPageCreateState)
          TextFormField(
            controller: passwordConfirmController,
            validator: _passwordConfirmValidator,
            obscureText: true,
            decoration: InputDecoration(
              labelText: translate("page.login.password.confirm"),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, LoginPageState state) {
    final String firstButtonKey = state is LoginPageCreateState ? "page.login.create" : "page.login.login";
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton(
          onPressed: () => _firstButtonPressed(context, state),
          child: Text(translate(firstButtonKey)),
        ),
        const SizedBox(height: 15),
        FilledButton.tonal(
          onPressed: () => _secondButtonPressed(context, state),
          child: Text(translate(_getSecondButtonKey(state))),
        ),
      ],
    );
  }

  String _getSecondButtonKey(LoginPageState state) {
    if (state is LoginPageCreateState) {
      return "page.login.instead.login";
    }
    if (state is LoginPageRemoteState) {
      return "page.login.instead.create";
    }
    if (state is LoginPageLocalState) {
      return "page.login.change.account";
    }
    throw UnimplementedError();
  }

  void _firstButtonPressed(BuildContext context, LoginPageState state) {
    if (state is LoginPageCreateState) {
      currentBloc(context).add(LoginPageEventCreate(
          username: usernameController.text,
          password: passwordController.text,
          confirmPassword: passwordConfirmController.text));
    } else if (state is LoginPageRemoteState) {
      currentBloc(context).add(LoginPageEventRemoteLogin(usernameController.text, passwordController.text));
    } else if (state is LoginPageLocalState) {
      currentBloc(context).add(LoginPageEventLocalLogin(passwordController.text));
    }
  }

  void _secondButtonPressed(BuildContext context, LoginPageState state) {
    if (state is LoginPageCreateState) {
      currentBloc(context).add(const LoginPageEventSwitchCreation(isCreateAccount: false));
    } else if (state is LoginPageRemoteState) {
      currentBloc(context).add(const LoginPageEventSwitchCreation(isCreateAccount: true));
    } else if (state is LoginPageLocalState) {
      currentBloc(context).add(const LoginPageEventChangeAccount());
    }
  }

  /// Returns error message, or null
  String? _usernameValidator(String? input) {
    if (input != null && input.isEmpty) {
      return translate("page.login.empty.user");
    }
    return null;
  }

  String? _passwordValidator(String? input) {
    if (input != null) {
      if (_checkPassword(input) == false) {
        return translate("page.login.unsecure.password");
      }
    }
    return null;
  }

  String? _passwordConfirmValidator(String? input) {
    if (input != null && input != passwordController.text) {
      return translate("page.login.no.password.match");
    }
    return null;
  }

  /// The password should contain at least 4 characters and it should contain at least one lowercase letter, one uppercase
  /// letter and one number.
  bool _checkPassword(String password) =>
      password.length >= 4 &&
      RegExp(r"[A-Z]").hasMatch(password) &&
      RegExp(r"[a-z]").hasMatch(password) &&
      RegExp(r"\d").hasMatch(password);

  @override
  String get pageName => "login";
}
