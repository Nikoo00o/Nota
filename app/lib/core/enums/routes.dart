import 'package:app/presentation/main/app/widgets/custom_navigator.dart';

/// The different Routes of the app pages used inside of [CustomNavigator].
enum Routes {
  /// invalid / no route special case!
  invalid,
  login,
  note_selection,
  note_edit,
  note_edit_file,
  settings,
  logs,

  /// Test pages:
  material_color_test,
  dialog_test,
  splash_screen_test;

  /// The first page of the app.
  static Routes get firstRoute => login;

  factory Routes.fromString(String? routeName) {
    final Iterable<Routes> route = values.where((Routes element) => element.name == routeName);
    if (route.isNotEmpty) {
      return route.first;
    }
    return Routes.invalid;
  }

  @override
  String toString() {
    return name;
  }
}
