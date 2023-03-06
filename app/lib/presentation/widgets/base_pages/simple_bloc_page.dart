import 'package:app/core/get_it.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/base_pages/no_bloc_page.dart';
import 'package:app/presentation/widgets/base_pages/page_base.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This is an abstract super class that can be used for the pages which are used with a bloc.
///
/// This is a simplified version of [BlocPage] combined with the page building of [NoBlocPage].
/// This uses [buildPage] to build the page and the [buildBody] method should be overridden in the subclass to build the
/// page body. The methods [buildAppBar] and [buildMenuDrawer] can also be overridden.
///
/// The performance of this is a bit worse than [BlocPage], because everything is rebuild on state changes.
abstract class SimpleBlocPage<Bloc extends PageBloc<PageEvent, State>, State extends PageState>
    extends BlocPage<Bloc, State> {
  const SimpleBlocPage({
    super.key,
    super.backGroundImage,
    super.backgroundColour,
    super.pagePadding,
  });

  @override
  Widget build(BuildContext context) {
    return buildBlocProvider(buildPartWithNoState(context, buildBlocBuilder(builder: (BuildContext context, State state) {
      return buildPage(context, state, buildBody(context, state));
    })));
  }

  /// builds the page [body] expanded with a padding around it and background image, or background colour.
  ///
  /// Everything will be build inside of a [Scaffold] which can also use [buildAppBar] and
  /// [buildMenuDrawer].
  Widget buildPage(BuildContext context, State state, Widget body) {
    return GestureDetector(
      onTapDown: (TapDownDetails details) => unFocus(context),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(image: getBackground(), color: backGroundImage == null ? backgroundColour : null),
          child: Padding(
            padding: pagePadding,
            child: Column(
              children: <Widget>[
                Expanded(child: body),
              ],
            ),
          ),
        ),
        appBar: buildAppBar(context, state),
        drawer: buildMenuDrawer(context, state),
      ),
    );
  }

  /// This can be overridden inside of a subclass to build an app bar for this page.
  PreferredSizeWidget? buildAppBar(BuildContext context, State state) => null;

  /// This can be overridden inside of a subclass to build a menu drawer for this page.
  Widget? buildMenuDrawer(BuildContext context, State state) => null;

  /// This builds the body of the page which will be rebuild when the [state] changes and must be overridden in the subclass!
  Widget buildBody(BuildContext context, State state);
}
