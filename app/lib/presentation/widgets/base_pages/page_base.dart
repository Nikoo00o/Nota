import 'dart:async';

import 'package:app/presentation/main/app/widgets/page_route_animation.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/base_pages/no_bloc_page.dart';
import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

/// Use one of the subclasses [BlocPage], or [NoBlocPage] and not this class.
///
/// This is only the abstract base class to provide common member variables.
///
/// You can also override [customBackNavigation] to provide a custom back navigation.
/// Per default, a confirmation dialog will be opened if the app should be closed.
abstract class PageBase extends WidgetBase {
  /// The default page padding
  static const EdgeInsets defaultPagePadding = EdgeInsets.fromLTRB(8, 8, 8, 8);

  /// if background image should be shown for body
  final AssetImage? backGroundImage;

  /// only shown if background image is not shown
  final Color? backgroundColor;

  /// default padding is (20, 5, 20, 20)
  final EdgeInsetsGeometry pagePadding;

  /// If this is set to true, then a touch outside of a text input field, will reset the focus of the selected field and
  /// hide the keyboard again.
  final bool resetFocusOnTouch;

  const PageBase({
    super.key,
    this.backGroundImage,
    this.backgroundColor,
    this.resetFocusOnTouch = true,
    EdgeInsetsGeometry? pagePadding,
  }) : pagePadding = pagePadding ?? defaultPagePadding;

  /// Returns [backGroundImage] if not its not null
  DecorationImage? getBackgroundImage() {
    if (backGroundImage != null) {
      return DecorationImage(image: backGroundImage!, fit: BoxFit.cover);
    }
    return null;
  }

  /// Returns the [backgroundColor] if the [backGroundImage] is null, otherwise this returns null.
  ///
  /// If the [backgroundColor] is null as well, then the themes [colorScaffoldBackground] color will be used, which is the
  /// same as the [colorBackground] and this method here returns null as well.
  Color? getBackgroundColor(BuildContext context) {
    if (backGroundImage != null) {
      return null;
    }
    if (backgroundColor != null) {
      return backgroundColor!;
    }
    return null; // default from theme
  }

  /// pop current page
  void popPage(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// push next page
  void pushPage(BuildContext context, Widget page) {
    Navigator.push<void>(context, PageRouteAnimation(child: page));
  }

  /// Clears the focus of all text input fields and hides the keyboard
  void unFocus(BuildContext context) {
    final FocusScopeNode currentFocus = FocusScope.of(context);
    if (currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    } else if (currentFocus.focusedChild?.hasPrimaryFocus ?? false) {
      currentFocus.focusedChild!.unfocus();
    }
  }

  /// The page name for logging.
  ///
  /// This needs to be overridden in the subclass
  String get pageName;

  /// this is called internally and builds the page [body] expanded with a padding around it and background image, or
  /// background color.
  ///
  /// Everything will be build inside of a [Scaffold] which can also uses the [appBar] and [menuDrawer].
  Widget buildPage(BuildContext context, Widget body, PreferredSizeWidget? appBar, Widget? menuDrawer) {
    return WillPopScope(
      onWillPop: () async => customBackNavigation(context),
      child: GestureDetector(
        onTapDown: (TapDownDetails details) => unFocus(context),
        child: Scaffold(
          body: Container(
            padding: pagePadding,
            decoration: BoxDecoration(image: getBackgroundImage(), color: getBackgroundColor(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: body),
              ],
            ),
          ),
          appBar: appBar,
          drawer: menuDrawer,
        ),
      ),
    );
  }

  /// You can override this to provide a custom back navigation from this page.
  ///
  /// Returns false if a custom back navigation was executed and the default back navigation from the app observer should
  /// not be executed.
  /// Returns true if there was no custom back navigation and the default way of showing a close app confirm dialog
  /// should be executed.
  ///
  /// Per default this just returns true.
  Future<bool> customBackNavigation(BuildContext context) async => true;
}
