import 'package:app/core/utils/input_validator.dart';
import 'package:app/presentation/pages/login/login_bloc.dart';
import 'package:app/presentation/pages/login/login_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class LoginInputs extends BlocPageChild<LoginBloc, LoginState> {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;

  const LoginInputs({
    required this.usernameController,
    required this.passwordController,
    required this.passwordConfirmController,
  });

  @override
  Widget buildWithState(BuildContext context, LoginState state) {
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
            validator: state is LoginCreateState ? _passwordValidator : null,
            textKey: "page.login.password",
            obscureText: true,
          ),
          if (state is LoginCreateState) const SizedBox(height: space),
          if (state is LoginCreateState)
            CustomTextFormField(
              controller: passwordConfirmController,
              validator: _passwordConfirmValidator,
              textKey: "page.login.password.confirm",
              obscureText: true,
            ),
        ],
      ),
    );
  }

  /// Returns error message, or null
  String? _usernameValidator(String? input) {
    return null;
  }

  String? _passwordValidator(String? input) {
    if (input != null && input.isNotEmpty) {
      if (InputValidator.validatePassword(input) == false) {
        return translate("page.login.insecure.password");
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
}
