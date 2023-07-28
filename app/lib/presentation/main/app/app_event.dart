import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:flutter/material.dart';

sealed class AppEvent extends PageEvent {
  const AppEvent();
}

final class AppUpdateLocale extends AppEvent {
  final Locale locale;

  const AppUpdateLocale(this.locale);
}

final class AppUpdateTheme extends AppEvent {
  final bool useDarkTheme;

  const AppUpdateTheme({required this.useDarkTheme});
}
