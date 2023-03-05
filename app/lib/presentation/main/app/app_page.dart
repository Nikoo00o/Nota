import 'package:app/core/config/app_config.dart';
import 'package:app/core/constants/locales.dart';
import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/app/app_bloc.dart';
import 'package:app/presentation/main/app/app_state.dart';
import 'package:app/presentation/main/app/widgets/app_observer.dart';
import 'package:app/presentation/main/app/widgets/custom_navigator.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_page.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:app/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// The top level widget that builds the app itself with the widget subtree
class App extends StatelessWidget {
  final AppConfig appConfig;
  final NavigationService navigationService;
  final DialogService dialogService;
  final SessionService sessionService;

  const App({
    required this.appConfig,
    required this.navigationService,
    required this.dialogService,
    required this.sessionService,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppBloc>(
      create: (_) => sl<AppBloc>(),
      child: BlocBuilder<AppBloc, AppState>(
        builder: (BuildContext context, AppState state) {
          return MaterialApp(
            title: appConfig.appTitle,
            debugShowCheckedModeBanner: false,
            supportedLocales: Locales.supportedLocales,
            locale: state.locale,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _buildStructure(context, state),
          );
        },
      ),
    );
  }

  /// Builds the app observer around everything and then the dialog overlay above the custom navigator which displays the
  /// pages.
  Widget _buildStructure(BuildContext context, AppState state) {
    return AppObserver(
      dialogService: dialogService,
      sessionService: sessionService,
      child: DialogOverlayPage(
        navigationService: navigationService,
        child: _buildPage(context, state),
      ),
    );
  }

  /// Builds the page with the navigator and a background colour and the safe area!
  Widget _buildPage(BuildContext context, AppState state) {
    return Container(
      color: appConfig.theme.colorScheme.background,
      child: SafeArea(
        child: CustomNavigator(navigationService: navigationService),
      ),
    );
  }
}
