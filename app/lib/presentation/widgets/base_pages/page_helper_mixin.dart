import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/app/widgets/page_route_animation.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/base_pages/page_base.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';

/// Provides some helper functions to both [PageBase] and [BlocPageChild] for navigating, etc.
mixin PageHelperMixin {
  /// Navigates to the given [route] by using the [NavigationService].
  ///
  /// This is for navigating with routes!
  void navigateTo(String routeName, {Object? arguments}) {
    // direct access
    sl<NavigationService>().navigateTo(routeName, arguments: arguments);
  }

  /// pops the current page if one was added on top of the routes with [pushPage].
  ///
  /// This is for navigating without routes!
  void popPage(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// pushes a new page (that has no route) on top of the navigator without removing other stored pages.
  ///
  /// This is for navigating without routes!
  void pushPage(BuildContext context, Widget page) {
    Navigator.push<void>(context, PageRouteAnimation(child: page));
  }

  /// Shows the left menu only if the [context] is below a [Scaffold]!
  void openMenuDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  /// Hides the left menu only if the [context] is below a [Scaffold]!
  void closeMenuDrawer(BuildContext context) {
    Scaffold.of(context).closeDrawer();
  }

  /// Returns if the left menu is open only if the [context] is below a [Scaffold]!
  bool isMenuDrawerOpen(BuildContext context) => Scaffold.of(context).isDrawerOpen;

  /// Clears the focus of all text input fields and hides the keyboard
  void unFocus(BuildContext context) {
    final FocusScopeNode currentFocus = FocusScope.of(context);
    if (currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    } else if (currentFocus.focusedChild?.hasPrimaryFocus ?? false) {
      currentFocus.focusedChild!.unfocus();
    }
  }
}
