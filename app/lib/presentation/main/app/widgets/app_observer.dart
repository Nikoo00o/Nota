import 'package:app/services/dialog_service.dart';
import 'package:app/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/utils/logger/logger.dart';

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

  const AppObserver({required this.child, required this.dialogService, required this.sessionService});

  @override
  _AppObserverState createState() => _AppObserverState();
}

class _AppObserverState extends State<AppObserver> with WidgetsBindingObserver {
  bool? _resumedFromBackground;

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
        if (_resumedFromBackground == null || _resumedFromBackground == false) {
          _onPause();
        }
        _resumedFromBackground = true;
      } else if (state == AppLifecycleState.resumed) {
        if (_resumedFromBackground == true) {
          _onResume();
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

  }

  Future<void> _onResume() async {

  }
}
