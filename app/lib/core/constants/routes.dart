import 'package:app/presentation/main/app/widgets/custom_navigator.dart';

/// The different Routes of the app pages used inside of [CustomNavigator].
class Routes {
  /// The first page of the app.
  static const String firstRoute = login;

  static const String login = "login";

  static const String note_selection = "note_selection";

  static const String note_edit = "note_edit";

  static const String settings = "settings";

  static const String logs = "logs";

  /// Test pages:
  static const String material_color_test = "material_color_test";
  static const String dialog_test = "dialog_test";
  static const String splash_screen_test = "splash_screen_test";

}
