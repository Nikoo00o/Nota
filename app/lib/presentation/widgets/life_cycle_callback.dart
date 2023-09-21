import 'package:flutter/material.dart';

/// use it inside pages, etc to handle the callbacks onresume, onpause of the app, etc
class LifeCycleCallback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onResume;
  final VoidCallback? onPause;

  const LifeCycleCallback({
    super.key,
    required this.child,
    this.onResume,
    this.onPause,
  });

  @override
  _LifeCycleCallbackState createState() => _LifeCycleCallbackState();
}

class _LifeCycleCallbackState extends State<LifeCycleCallback> {
  late final AppLifecycleListener _listener;
  bool? _resumedFromBackground;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: _onStateChange);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _onStateChange(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.onPause?.call();
      _resumedFromBackground = true;
    } else if (state == AppLifecycleState.resumed) {
      if (_resumedFromBackground == true) {
        widget.onResume?.call(); // not called at the start of the app
      }
      _resumedFromBackground = false;
    }
  }
}
