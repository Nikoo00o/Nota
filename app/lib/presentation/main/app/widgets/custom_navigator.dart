import 'package:app/core/config/app_config.dart';
import 'package:app/core/constants/routes.dart';
import 'package:app/presentation/main/app/widgets/page_route_animation.dart';
import 'package:app/presentation/pages/login/login_page.dart';
import 'package:app/presentation/pages/note_edit/note_edit_page.dart';
import 'package:app/presentation/pages/note_selection/note_selection_page.dart';
import 'package:app/presentation/pages/settings/settings_page.dart';
import 'package:app/presentation/pages/test/dialog_test_page.dart';
import 'package:app/presentation/pages/test/material_color_test_page.dart';
import 'package:app/presentation/pages/test/splash_screen_test_page.dart';
import 'package:app/presentation/widgets/base_pages/page_base.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// The navigator that navigates to the different [Routes] for which a [PageBase] has to be returned inside of
/// [_getPageForRoute]!
class CustomNavigator extends StatelessWidget {
  final NavigationService navigationService;
  final AppConfig appConfig;

  const CustomNavigator({required this.navigationService, required this.appConfig});

  // todo: return all pages for the routes here!
  Widget _getPageForRoute(String? routeName, Object? arguments) {
    switch (routeName) {
      case Routes.login:
        return const LoginPage();
      case Routes.note_selection:
        return const NoteSelectionPage();
      case Routes.note_edit:
        return const NoteEditPage();
      case Routes.settings:
        return const SettingsPage();
      case Routes.material_color_test:
        return const MaterialColorTestPage();
      case Routes.splash_screen_test:
        return const SplashScreenTestPage();
      case Routes.dialog_test:
        return const DialogTestPage();
      default:
        return Scaffold(body: Center(child: Text("no page found for route: $routeName")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: Routes.firstRoute,
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
    Logger.debug("push page from '${previousRoute?.settings.name}' to '${route.settings.name}'");
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    Logger.debug("pop page from '${previousRoute?.settings.name}' to '${route.settings.name}'");
  }
}
