import 'package:app/core/constants/routes.dart';
import 'package:app/presentation/main/app/widgets/page_route_animation.dart';
import 'package:app/presentation/widgets/base_pages/page_base.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// The navigator that navigates to the different [Routes] for which a [PageBase] has to be returned inside of
/// [_getPageForRoute]!
class CustomNavigator extends StatelessWidget {
  final NavigationService navigationService;

  const CustomNavigator({required this.navigationService});

  // todo: return all pages for the routes here!
  Widget _getPageForRoute(String? routeName, Object? arguments) {
    return Scaffold(body: Center(child: Text("no page found for route: $routeName")));
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: Routes.login,
      key: navigationService.navigatorKey,
      observers: <NavigatorObserver>[_CustomNavigatorObserver()],
      onGenerateRoute: (RouteSettings settings) {
        return PageRouteAnimation(child: _getPageForRoute(settings.name, settings.arguments));
      },
    );
  }
}

class _CustomNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    Logger.info("push page from '${previousRoute?.settings.name}' to '${route.settings.name}'");
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    Logger.info("pop page from '${previousRoute?.settings.name}' to '${route.settings.name}'");
  }
}
