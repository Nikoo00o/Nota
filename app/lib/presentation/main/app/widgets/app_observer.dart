import 'dart:async';

import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/usecases/account/change/activate_lock_screen.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
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
  final NavigationService navigationService;
  final AppSettingsRepository appSettingsRepository;
  final ActivateLockscreen activateLockscreen;

  const AppObserver({
    required this.child,
    required this.dialogService,
    required this.sessionService,
    required this.navigationService,
    required this.appSettingsRepository,
    required this.activateLockscreen,
  });

  @override
  _AppObserverState createState() => _AppObserverState();
}

class _AppObserverState extends State<AppObserver> {
  late final AppLifecycleListener _listener;
  bool? _resumedFromBackground;
  DateTime? _pauseTime;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onInactive: () => Logger.debug("App Lifecycle: resumed -> inactive"),
      onResume: () => Logger.debug("App Lifecycle: inactive -> resumed"),
      onHide: () => Logger.debug("App Lifecycle: inactive -> hidden"),
      onShow: () => Logger.debug("App Lifecycle: hidden -> inactive"),
      onPause: () => Logger.debug("App Lifecycle: hidden -> paused"),
      onRestart: () => Logger.debug("App Lifecycle: paused -> hidden"),
      onDetach: () => Logger.debug("App Lifecycle: paused -> detached"),
      onStateChange: _onStateChange,
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _onWillPop(context),
      child: widget.child,
    );
  }

  /// Returns false if a custom back navigation was executed and the default pop should not happen.
  /// Returns true if the app should navigate back (in most cases terminate the app)
  Future<bool> _onWillPop(BuildContext context) async {
    // call the custom back navigation of the page if there is a nested WillPopScope. If one is found, call that one
    // instead of this one!
    Logger.verbose("navigating back");
    final bool? childHandledIt = await widget.navigationService.navigatorKey.currentState?.maybePop();
    if (childHandledIt == true) {
      return false;
    }

    // true if app should be closed, false if not
    final Completer<bool> closeApp = Completer<bool>();
    widget.dialogService.show(ShowConfirmDialog(
      descriptionKey: "page.app.should.close",
      confirmButtonKey: "yes",
      cancelButtonKey: "no",
      onConfirm: () => closeApp.complete(true),
      onCancel: () => closeApp.complete(false),
    ));
    return closeApp.future;
  }

  void _onStateChange(AppLifecycleState state) {
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
  }

  Future<void> _onPause() async {
    _pauseTime = DateTime.now();
  }

  Future<void> _onResume() async {
    final Duration timeout = await widget.appSettingsRepository.getLockscreenTimeout();
    if (_pauseTime != null && DateTime.now().isAfter(_pauseTime!.add(timeout))) {
      await widget.activateLockscreen(const NoParams()); // navigate to login page for a new local login
      //todo: should some written note data get auto saved when minimizing the app, or should it be discarded?
    }
  }
}
