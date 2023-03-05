import 'package:app/presentation/widgets/base_pages/page_base.dart';
import 'package:flutter/material.dart';

/// An abstract super class used for the pages which are used without a bloc.
///
/// The [buildBody] method should be overridden in the subclass to build the page.
abstract class NoBlocPage extends PageBase {
  const NoBlocPage({
    super.key,
    super.backGroundImage,
    super.backgroundColour,
    super.pagePadding,
  });

  @override
  Widget build(BuildContext context) {
    return buildPage(context, buildBody(context));
  }

  /// builds the body of the page.
  ///
  /// Needs to be overridden in sub classes
  Widget buildBody(BuildContext context);
}
