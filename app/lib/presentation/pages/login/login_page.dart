import 'package:app/core/get_it.dart';
import 'package:app/presentation/pages/login/login_bloc.dart';
import 'package:app/presentation/pages/login/login_event.dart';
import 'package:app/presentation/pages/login/login_state.dart';
import 'package:app/presentation/widgets/base_pages/simple_bloc_page.dart';
import 'package:app/presentation/widgets/custom_outlined_button.dart';
import 'package:app/presentation/widgets/custom_text_form_field.dart';
import 'package:app/presentation/widgets/nota_icon.dart';
import 'package:flutter/material.dart';

class LoginPage extends SimpleBlocPage<LoginBloc, LoginState> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  LoginPage() : super();

  @override
  LoginBloc createBloc(BuildContext context) {
    final LoginBloc bloc = sl<LoginBloc>();
    bloc.usernameController = usernameController;
    bloc.passwordController = passwordController;
    bloc.passwordConfirmController = passwordConfirmController;
    bloc.scrollController = scrollController;
    return bloc..add(const LoginEventInitialise());
  }

  @override
  Widget buildBody(BuildContext context, LoginState state) {
    return Center(
      child: Scrollbar(
        scrollbarOrientation: ScrollbarOrientation.right,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(40, 10, 40, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildDescription(context, state),
              const SizedBox(height: 25),
              _buildInput(context, state),
              const SizedBox(height: 25),
              _buildButtons(context, state),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context, LoginState state) {
    return AppBar(centerTitle: false, title: Text(translate(_getPageTitle(state))));
  }

  Widget _buildDescription(BuildContext context, LoginState state) {
    return Column(
      children: <Widget>[
        const NotaIcon(),
        const SizedBox(height: 20),
        Text(translate(_getPageDescription(state))),
      ],
    );
  }

  Widget _buildInput(BuildContext context, LoginState state) {
    const double space = 15; //height between fields
    return Form(
      autovalidateMode: AutovalidateMode.always,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          if (state is LoginRemoteState || state is LoginCreateState)
            CustomTextFormField(
              controller: usernameController,
              validator: _usernameValidator,
              textKey: "page.login.name",
            ),
          if (state is LoginRemoteState || state is LoginCreateState) const SizedBox(height: space),
          CustomTextFormField(
            controller: passwordController,
            validator: _passwordValidator,
            textKey: "page.login.password",
          ),
          if (state is LoginCreateState) const SizedBox(height: space),
          if (state is LoginCreateState)
            CustomTextFormField(
              controller: passwordConfirmController,
              validator: _passwordConfirmValidator,
              textKey: "page.login.password.confirm",
            ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context, LoginState state) {
    final String firstButtonKey = state is LoginCreateState ? "page.login.create" : "page.login.login";
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton(
          onPressed: () => _firstButtonPressed(context, state),
          key: state.firstButtonKey,
          child: Text(translate(firstButtonKey)),
        ),
        const SizedBox(height: 10),
        CustomOutlinedButton(
          onPressed: () => _secondButtonPressed(context, state),
          textKey: _getSecondButtonKey(state),
        ),
      ],
    );
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
    throw UnimplementedError();
  }

  String _getPageDescription(LoginState state) {
    if (state is LoginCreateState) {
      return "page.login.description.create";
    }
    if (state is LoginRemoteState) {
      return "page.login.description.remote.login";
    }
    if (state is LoginLocalState) {
      return "page.login.description.local.login";
    }
    throw UnimplementedError();
  }

  String _getSecondButtonKey(LoginState state) {
    if (state is LoginCreateState) {
      return "page.login.instead.login";
    }
    if (state is LoginRemoteState) {
      return "page.login.instead.create";
    }
    if (state is LoginLocalState) {
      return "page.login.change.account";
    }
    throw UnimplementedError();
  }

  void _firstButtonPressed(BuildContext context, LoginState state) {
    unFocus(context);
    if (state is LoginCreateState) {
      currentBloc(context).add(LoginEventCreate(
          username: usernameController.text,
          password: passwordController.text,
          confirmPassword: passwordConfirmController.text));
    } else if (state is LoginRemoteState) {
      currentBloc(context).add(LoginEventRemoteLogin(usernameController.text, passwordController.text));
    } else if (state is LoginLocalState) {
      currentBloc(context).add(LoginEventLocalLogin(passwordController.text));
    }
  }

  void _secondButtonPressed(BuildContext context, LoginState state) {
    unFocus(context);
    if (state is LoginCreateState) {
      currentBloc(context).add(const LoginEventSwitchCreation(isCreateAccount: false));
    } else if (state is LoginRemoteState) {
      currentBloc(context).add(const LoginEventSwitchCreation(isCreateAccount: true));
    } else if (state is LoginLocalState) {
      currentBloc(context).add(const LoginEventChangeAccount());
    }
  }

  /// Returns error message, or null
  String? _usernameValidator(String? input) {
    return null;
  }

  String? _passwordValidator(String? input) {
    if (input != null && input.isNotEmpty) {
      if (_checkPassword(input) == false) {
        return translate("page.login.unsecure.password");
      }
    }
    return null;
  }

  String? _passwordConfirmValidator(String? input) {
    if (input != null && input.isNotEmpty) {
      if (input != passwordController.text) {
        return translate("page.login.no.password.match");
      }
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
