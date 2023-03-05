import 'dart:ui';
import 'package:app/presentation/widgets/base_pages/page_state.dart';

class AppState extends PageState {
  final Locale locale;

  AppState(this.locale) : super(<String, Object?>{"locale": locale});
}
