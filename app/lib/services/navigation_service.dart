import 'package:app/core/constants/routes.dart';
import 'package:app/presentation/main/app/widgets/page_route_animation.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// Service used to navigate to another page with its route
class NavigationService {
  /// The navigator key used to access the navigator widget and its state!
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Start on initial route
  String _currentRoute = Routes.firstRoute;

  /// navigate to the new page with the route [routeName] if its different from the [currentRoute].
  ///
  /// The [arguments] parameter is optional to provide some page arguments to the page for initialisation!
  ///
  /// this also removes all stored pages, so that navigating back is not possible!
  void navigateTo(String routeName, {Object? arguments}) {
    Logger.verbose("navigating from $_currentRoute to $routeName");
    if (routeName != _currentRoute) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(routeName, (Route<dynamic> route) => false, arguments: arguments);
      _currentRoute = routeName;
    } else {
      Logger.warn("navigating to the same route as before: $routeName");
    }
  }

  /// pushes a new page (that has no route) on top of the navigator without removing other stored pages.
  ///
  /// Also resets the [currentRoute].
  void pushPage(Widget page) {
    navigatorKey.currentState?.push(PageRouteAnimation(child: page));
    _currentRoute = "";
  }

  /// navigate back to previous page if one is stored and also resets the [currentRoute].
  void navigateBack() {
    if (canPop) {
      navigatorKey.currentState?.pop();
    }
    _currentRoute = "";
  }

  /// if this navigator has a previous route/page stored that it can navigate back to
  bool get canPop => navigatorKey.currentState?.canPop() ?? false;

  /// Read only access to the current route (or rather the current page) of the navigator.
  String get currentRoute => _currentRoute;
}
