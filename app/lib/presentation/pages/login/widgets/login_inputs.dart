import 'package:app/core/utils/input_validator.dart';
import 'package:app/presentation/pages/login/login_bloc.dart';
import 'package:app/presentation/pages/login/login_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class LoginInputs extends BlocPageChild<LoginBloc, LoginState> {
  const LoginInputs();

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
              controller: currentBloc(context).usernameController,
              textKey: "page.login.name",
            ),
          if (state is LoginRemoteState || state is LoginCreateState) const SizedBox(height: space),
          CustomTextFormField(
            controller: currentBloc(context).passwordController,
            validator: state is LoginCreateState ? (String? input) => _passwordValidator(context, input) : null,
            textKey: "page.login.password",
            obscureText: true,
          ),
          if (state is LoginCreateState) const SizedBox(height: space),
          if (state is LoginCreateState)
            CustomTextFormField(
              controller: currentBloc(context).passwordConfirmController,
              validator: (String? input) => _passwordConfirmValidator(context, input),
              textKey: "page.login.password.confirm",
              obscureText: true,
            ),
        ],
      ),
    );
  }

  /// Returns error message, or null
  String? _passwordValidator(BuildContext context, String? input) {
    if (input != null && input.isNotEmpty) {
      if (InputValidator.validatePassword(input) == false) {
        return translate(context, "page.login.insecure.password");
      }
    }
    return null;
  }

  String? _passwordConfirmValidator(BuildContext context, String? input) {
    if (input != null && input.isNotEmpty) {
      if (input != currentBloc(context).passwordController.text) {
        return translate(context, "page.login.no.password.match");
      }
    }
    return null;
  }
}
