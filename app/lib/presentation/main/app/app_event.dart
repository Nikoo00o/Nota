import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:flutter/material.dart';

abstract class AppEvent extends PageEvent {
  const AppEvent();
}

class AppUpdateLocale extends AppEvent {
  final Locale locale;

  const AppUpdateLocale(this.locale);
}

class AppUpdateTheme extends AppEvent {
  final bool useDarkTheme;

  const AppUpdateTheme({required this.useDarkTheme});
}
