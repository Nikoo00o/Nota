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
  LoginLocalState({required super.firstButtonKey});
}

class LoginCreateState extends LoginState {
  LoginCreateState({required super.firstButtonKey});
}
