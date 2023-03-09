import 'package:app/presentation/widgets/base_pages/page_state.dart';
import 'package:flutter/material.dart';

abstract class LoginState extends PageState {
  final GlobalKey firstButtonKey;

  LoginState({required this.firstButtonKey})
      : super(<String, Object?>{
          "firstButtonKey": firstButtonKey,
        });
}

class LoginRemoteState extends LoginState {
  LoginRemoteState({required super.firstButtonKey});
}

class LoginLocalState extends LoginState {
  /// The username of the logged in user. not used for comparison!
  final String username;

  LoginLocalState({required super.firstButtonKey, required this.username});
}

class LoginCreateState extends LoginState {
  LoginCreateState({required super.firstButtonKey});
}
