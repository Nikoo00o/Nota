import 'package:app/core/get_it.dart';
import 'package:app/presentation/pages/login/login_bloc.dart';
import 'package:app/presentation/pages/login/login_event.dart';
import 'package:app/presentation/pages/login/login_state.dart';
import 'package:app/presentation/pages/login/widgets/login_buttons.dart';
import 'package:app/presentation/pages/login/widgets/login_description.dart';
import 'package:app/presentation/pages/login/widgets/login_inputs.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends BlocPage<LoginBloc, LoginState> {
  const LoginPage() : super();

  @override
  LoginBloc createBloc(BuildContext context) {
    final LoginBloc bloc = sl<LoginBloc>();
    return bloc..add(const LoginEventInitialise());
  }

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Center(
      child: Scrollbar(
        controller: currentBloc(context).scrollController,
        scrollbarOrientation: ScrollbarOrientation.right,
        child: SingleChildScrollView(
          controller: currentBloc(context).scrollController,
          padding: const EdgeInsets.fromLTRB(40, 5, 40, 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              LoginDescription(),
              SizedBox(height: 25),
              LoginInputs(),
              SizedBox(height: 25),
              LoginButtons(),
              SizedBox(height: BlocPage.defaultAppBarHeight),
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
    return AppBar(
      centerTitle: false,
      title: Text(
        translate(context, _getPageTitle(state)),
        style: textTitleLarge(context).copyWith(fontWeight: FontWeight.bold),
      ),
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
    return "empty";
  }

  @override
  String get pageName => "login";
}
