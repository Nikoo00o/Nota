import 'package:app/presentation/pages/login/login_bloc.dart';
import 'package:app/presentation/pages/login/login_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/nota_icon.dart';
import 'package:flutter/material.dart';

class LoginDescription extends BlocPageChild<LoginBloc, LoginState> {
  const LoginDescription();

  @override
  Widget buildWithState(BuildContext context, LoginState state) {
    if (state is LoginLocalState) {
      return _buildLocalDetailedDescription(context, state);
    }
    return Column(
      children: <Widget>[
        const NotaIcon(),
        const SizedBox(height: 25),
        Text(
          translate(context, _getPageDescription(state)),
          style: textBodyLarge(context),
          // textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLocalDetailedDescription(BuildContext context, LoginLocalState state) {
    return Column(
      children: <Widget>[
        const NotaIcon(),
        const SizedBox(height: 25),
        Text.rich(
          TextSpan(
            style: textBodyLarge(context),
            children: <InlineSpan>[
              TextSpan(
                text: translate(context, "page.login.description.local.login.1"),
              ),
              TextSpan(
                text: translate(context, "empty.param.1", keyParams: <String>[state.username]),
                style: textTitleLarge(context).copyWith(color: colorSecondary(context)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          translate(context, "page.login.description.local.login.2"),
          style: textBodyLarge(context),
        ),
      ],
    );
  }

  /// Does not include [LoginLocalState]
  String _getPageDescription(LoginState state) {
    if (state is LoginCreateState) {
      return "page.login.description.create";
    }
    if (state is LoginRemoteState) {
      return "page.login.description.remote.login";
    }
    return "empty";
  }
}
