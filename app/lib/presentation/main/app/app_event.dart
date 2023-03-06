import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:flutter/material.dart';

abstract class AppEvent extends PageEvent {
  const AppEvent();
}

class UpdateLocale extends AppEvent {
  final Locale locale;

  const UpdateLocale(this.locale);
}
