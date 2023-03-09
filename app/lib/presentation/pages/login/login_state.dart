import 'package:app/presentation/widgets/base_pages/page_state.dart';
import 'package:flutter/material.dart';

abstract class LoginState extends PageState {
  final GlobalKey firstButtonScrollKey;

  LoginState({required this.firstButtonScrollKey})
      : super(<String, Object?>{
          "firstButtonScrollKey": firstButtonScrollKey,
        });
}

class LoginRemoteState extends LoginState {
  LoginRemoteState({required super.firstButtonScrollKey});
}

class LoginLocalState extends LoginState {
  /// The username of the logged in user. not used for comparison!
  final String username;

  LoginLocalState({required super.firstButtonScrollKey, required this.username});
}

class LoginCreateState extends LoginState {
  LoginCreateState({required super.firstButtonScrollKey});
}
