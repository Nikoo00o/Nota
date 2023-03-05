import 'package:flutter/material.dart';

/// Service used to navigate to another page with its route
class NavigationService {
  /// The navigator key used to access the navigator widget and its state!
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// navigate to the new page with the route [routeName].
  ///
  /// The [arguments] parameter is optional to provide some page arguments to the page for initialisation!
  ///
  /// this also removes all stored pages, so that navigating back is not possible!
  void navigateTo(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(routeName, (Route<dynamic> route) => false, arguments: arguments);
  }

  /// pushes a new page on top of the navigator without removing other stored pages
  void pushPage(Widget page) {
    navigatorKey.currentState?.push(MaterialPageRoute<Widget>(builder: (BuildContext context) => page));
  }

  /// navigate back to previous page if one is stored
  void navigateBack() {
    if (canPop) {
      navigatorKey.currentState?.pop();
    }
  }

  /// if this navigator has a previous route/page stored that it can navigate back to
  bool get canPop => navigatorKey.currentState?.canPop() ?? false;
}
