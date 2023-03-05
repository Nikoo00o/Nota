import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:flutter/material.dart';

abstract class AppEvent extends PageEvent {}

class AppEventUpdateLocale extends AppEvent {
  final Locale locale;

  AppEventUpdateLocale(this.locale);
}
