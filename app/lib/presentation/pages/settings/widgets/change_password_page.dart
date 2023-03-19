import 'package:app/core/utils/input_validator.dart';
import 'package:app/presentation/pages/settings/settings_bloc.dart';
import 'package:app/presentation/pages/settings/settings_event.dart';
import 'package:app/presentation/pages/settings/settings_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/base_pages/reuse_bloc_page.dart';
import 'package:app/presentation/widgets/custom_outlined_button.dart';
import 'package:app/presentation/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends ReuseBlocPage<SettingsBloc, SettingsState> {
  const ChangePasswordPage({required super.bloc});

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Center(
      child: Scrollbar(
        controller: currentBloc(context).passwordScrollController,
        scrollbarOrientation: ScrollbarOrientation.right,
        child: SingleChildScrollView(
          controller: currentBloc(context).passwordScrollController,
          padding: const EdgeInsets.fromLTRB(40, 5, 40, 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(translate(context, "page.change.password.description")),
              const SizedBox(height: 25),
              _buildInput(context),
              const SizedBox(height: 25),
              _buildButtons(context),
              const SizedBox(height: BlocPage.defaultAppBarHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Form(
      autovalidateMode: AutovalidateMode.always,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          CustomTextFormField(
            controller: currentBloc(context).passwordController,
            validator: (String? input) => _passwordValidator(context, input),
            textKey: "page.login.password",
            obscureText: true,
          ),
          const SizedBox(height: 15),
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

  Widget _buildButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton(
          onPressed: () => currentBloc(context).add(const SettingsPasswordChanged(cancel: false)),
          child: Text(translate(context, "confirm")),
        ),
        const SizedBox(height: 10),
        CustomOutlinedButton(
          onPressed: () => currentBloc(context).add(const SettingsPasswordChanged(cancel: true)),
          textKey: "cancel",
        ),
      ],
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

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        translate(context, "page.settings.password"),
        style: textTitleLarge(context).copyWith(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
    );
  }
}
