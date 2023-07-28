import 'package:app/presentation/pages/login/login_bloc.dart';
import 'package:app/presentation/pages/login/login_event.dart';
import 'package:app/presentation/pages/login/login_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/custom_outlined_button.dart';
import 'package:flutter/material.dart';

final class LoginButtons extends BlocPageChild<LoginBloc, LoginState> {
  const LoginButtons();

  @override
  Widget buildWithState(BuildContext context, LoginState state) {
    if (state is LoginErrorState) {
      return const SizedBox();
    }
    final String firstButtonKey = state is LoginCreateState ? "page.login.create" : "page.login.login";
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton(
          onPressed: () => _firstButtonPressed(context, state),
          key: currentBloc(context).firstButtonScrollKey,
          child: Text(translate(context, firstButtonKey)),
        ),
        const SizedBox(height: 10),
        CustomOutlinedButton(
          onPressed: () => _secondButtonPressed(context, state),
          textKey: _getSecondButtonKey(state),
        ),
      ],
    );
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
    return "empty";
  }

  void _firstButtonPressed(BuildContext context, LoginState state) {
    unFocus(context);
    if (state is LoginCreateState) {
      currentBloc(context).add(const LoginEventCreate());
    } else if (state is LoginRemoteState) {
      currentBloc(context).add(const LoginEventRemoteLogin());
    } else if (state is LoginLocalState) {
      currentBloc(context).add(const LoginEventLocalLogin());
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
}
