import 'package:app/presentation/main/app/widgets/page_route_animation.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/base_pages/no_bloc_page.dart';
import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

/// Use one of the subclasses [BlocPage], or [NoBlocPage] and not this class.
///
/// This is only the abstract base class.
abstract class PageBase extends WidgetBase {
  /// The default page padding
  static const EdgeInsets defaultPagePadding = EdgeInsets.fromLTRB(8, 8, 8, 8);

  /// if background image should be shown for body
  final AssetImage? backGroundImage;

  /// only shown if background image is not shown
  final Color? backgroundColour;

  /// default padding is (20, 5, 20, 20)
  final EdgeInsetsGeometry pagePadding;

  const PageBase({
    super.key,
    this.backGroundImage,
    this.backgroundColour,
    EdgeInsetsGeometry? pagePadding,
  }) : pagePadding = pagePadding ?? defaultPagePadding;

  /// builds the page [body] expanded with a padding around it and background image, or background colour
  Widget buildPage(BuildContext context, Widget body) {
    return Container(
      decoration: BoxDecoration(image: _getBackground(), color: backGroundImage == null ? backgroundColour : null),
      child: Padding(
        padding: pagePadding,
        child: Column(
          children: <Widget>[
            Expanded(
              child: body,
            ),
          ],
        ),
      ),
    );
  }

  DecorationImage? _getBackground() {
    if (backGroundImage != null) {
      return DecorationImage(image: backGroundImage!, fit: BoxFit.cover);
    }
    return null;
  }

  /// pop current page
  void popPage(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// push next page
  void pushPage(BuildContext context, Widget page) {
    Navigator.push<void>(context, PageRouteAnimation(child: page));
  }

  /// The page name for logging.
  ///
  /// This needs to be overridden in the subclass
  String get pageName;
}
