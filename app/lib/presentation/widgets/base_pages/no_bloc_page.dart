import 'package:app/presentation/widgets/base_pages/page_base.dart';
import 'package:flutter/material.dart';

/// An abstract super class used for the pages which are used without a bloc.
///
/// This uses [buildPage] to build the page and the [buildBody] method should be overridden in the subclass to build the
/// page body. The methods [buildAppBar] and [buildMenuDrawer] can also be overridden.
abstract class NoBlocPage extends PageBase {
  const NoBlocPage({
    super.key,
    super.backGroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  @override
  Widget build(BuildContext context) {
    return buildPage(context, buildBody(context));
  }

  /// builds the page [body] expanded with a padding around it and background image, or background color.
  ///
  /// Everything will be build inside of a [Scaffold] which can also use [buildAppBar] and
  /// [buildMenuDrawer].
  Widget buildPage(BuildContext context, Widget body) {
    return GestureDetector(
      onTapDown: (TapDownDetails details) => unFocus(context),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(image: getBackground(), color: backGroundImage == null ? backgroundColor : null),
          child: Padding(
            padding: pagePadding,
            child: Column(
              children: <Widget>[
                Expanded(child: body),
              ],
            ),
          ),
        ),
        appBar: buildAppBar(context),
        drawer: buildMenuDrawer(context),
      ),
    );
  }

  /// This can be overridden inside of a subclass to build an app bar for this page.
  PreferredSizeWidget? buildAppBar(BuildContext context) => null;

  /// This can be overridden inside of a subclass to build a menu drawer for this page.
  Widget? buildMenuDrawer(BuildContext context) => null;

  /// builds the body of the page.
  ///
  /// Needs to be overridden in sub classes
  Widget buildBody(BuildContext context);
}
