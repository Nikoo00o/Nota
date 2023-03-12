import 'package:app/presentation/widgets/base_pages/page_state.dart';
import 'package:flutter/material.dart';

class AppState extends PageState {
  const AppState([super.properties = const <String, Object?>{}]);
}

class AppStateInitialised extends AppState {
  final Locale locale;
  final ThemeData theme;

  AppStateInitialised({required this.locale, required this.theme})
      : super(<String, Object?>{
          "locale": locale,
          "theme": theme,
        });
}
