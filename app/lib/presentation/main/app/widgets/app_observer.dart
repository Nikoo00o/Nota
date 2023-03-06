import 'package:app/core/config/app_config.dart';
import 'package:app/domain/usecases/account/change/activate_screen_saver.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// Top level widget to observe states like the app life cycle of the app.
///
/// Handles onresume, onpause of the app, etc.
///
/// Also adds a custom back navigation.
///
/// This uses some services.
class AppObserver extends StatefulWidget {
  final Widget child;

  final DialogService dialogService;
  final SessionService sessionService;
  final AppConfig appConfig;
  final ActivateScreenSaver activateScreenSaver;

  const AppObserver({
    required this.child,
    required this.dialogService,
    required this.sessionService,
    required this.appConfig,
    required this.activateScreenSaver,
  });

  @override
  _AppObserverState createState() => _AppObserverState();
}

class _AppObserverState extends State<AppObserver> with WidgetsBindingObserver {
  bool? _resumedFromBackground;
  DateTime? _pauseTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _onWillPop(context),
      child: widget.child,
    );
  }

  /// Returns false if a custom back navigation was executed.
  /// Returns true if the app should navigate back (in most cases terminate the app)
  Future<bool> _onWillPop(BuildContext context) async {
    //todo: custom back navigation (maybe show confirm dialog, or hide error dialog if open, etc)
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Logger.debug("App life cycle state changed to: $state");
    try {
      if (state == AppLifecycleState.paused) {
        _onPause();
        _resumedFromBackground = true;
      } else if (state == AppLifecycleState.resumed) {
        if (_resumedFromBackground == true) {
          _onResume(); // not called at the start of the app
        }
        _resumedFromBackground = false;
      }
    } catch (e, s) {
      Logger.error("App life cycle error for state $state", e, s);
      //todo: maybe show error dialog
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _onPause() async {
    _pauseTime = DateTime.now();
  }

  Future<void> _onResume() async {
    if (_pauseTime != null && DateTime.now().isAfter(_pauseTime!.add(widget.appConfig.screenSaverTimeout))) {
      await widget.activateScreenSaver(const NoParams()); // navigate to login page for a new local login
      //todo: should some written note data get auto saved when minimizing the app, or should it be discarded?
    }
  }
}
