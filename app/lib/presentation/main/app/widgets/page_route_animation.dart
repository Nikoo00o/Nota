import 'package:app/presentation/widgets/base_pages/page_base.dart';
import 'package:flutter/material.dart';

/// The page route builder that transitions from the current to the next page.
class PageRouteAnimation extends PageRouteBuilder<dynamic> {
  final Widget child;

  PageRouteAnimation({required this.child})
      : super(
          settings: child is PageBase ? RouteSettings(name: child.pageName) : null,
          transitionDuration: Duration.zero,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return child;
          },
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return child;
          },
        );
}
