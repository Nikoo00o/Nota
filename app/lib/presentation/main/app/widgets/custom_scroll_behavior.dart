import 'package:flutter/material.dart';

/// Removes the default material blue glow while overscrolling
class CustomScrollBehavior extends ScrollBehavior {
  const CustomScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
