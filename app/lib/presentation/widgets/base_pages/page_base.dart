import 'dart:async';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/base_pages/no_bloc_page.dart';
import 'package:app/presentation/widgets/base_pages/page_helper_mixin.dart';
import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

/// Use one of the subclasses [BlocPage], or [NoBlocPage] and not this class.
///
/// This is only the abstract base class for page routes to provide common member variables.
///
/// You can also override [customBackNavigation] to provide a custom back navigation.
/// Per default, a confirmation dialog will be opened if the app should be closed.
/// But if the menu is open, then it will be closed.
abstract class PageBase extends WidgetBase with PageHelperMixin {
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

  /// The page name for logging.
  ///
  /// This needs to be overridden in the subclass
  String get pageName;

  /// this is called internally and builds the page [body] expanded with a padding around it and background image, or
  /// background color.
  ///
  /// Everything will be build inside of a [Scaffold] which can also uses the [appBar] and [menuDrawer].
  Widget buildPage(
    BuildContext context, {
    required Widget body,
    required PreferredSizeWidget? appBar,
    required Widget? menuDrawer,
    required Widget? bottomBar,
  }) {
    return Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => _onWillPopScope(context),
            child: GestureDetector(
              onTap: () => unFocus(context),
              child: Container(
                padding: pagePadding,
                decoration: BoxDecoration(image: getBackgroundImage(), color: getBackgroundColor(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(child: body),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      appBar: appBar,
      drawer: menuDrawer,
      bottomNavigationBar: bottomBar,
    );
  }

  Future<bool> _onWillPopScope(BuildContext context) async {
    if (isMenuDrawerOpen(context)) {
      closeMenuDrawer(context);
      return false;
    }
    return customBackNavigation(context);
  }

  /// You can override this to provide a custom back navigation from this page.
  ///
  /// Returns false if a custom back navigation was executed and the default back navigation from the app observer should
  /// not be executed.
  /// Returns true if there was no custom back navigation and the default way of showing a close app confirm dialog
  /// should be executed.
  ///
  /// Per default this just returns true.
  ///
  /// This will not be called if the menu is open, because then the menu will be closed first!
  Future<bool> customBackNavigation(BuildContext context) async => true;
}
