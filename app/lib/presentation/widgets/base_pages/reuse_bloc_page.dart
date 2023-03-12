import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This is an abstract super class that can be used to use the same bloc as a [BlocPage].
///
/// Important: this should never be used as a route!!! It should only be used if a page (that extends from this class) is
/// pushed on top of a bloc page (without removing the bloc page) and if this page should be popped to navigate back to
/// the bloc page.
///
/// Then this page can also use the bloc of the other bloc page, but therefor the other page and its bloc must still be
/// alive!!!
///
/// So the generic template types first [Bloc], then [State] need to match those of the other page!
///
/// This has the same helper methods as [BlocPage], because it extends from it!
/// Only the [pageName] and the [customBackNavigation] should not be used.
///
/// This overrides [createBloc] and [createBlocProvider] to return the [bloc].
abstract class ReuseBlocPage<Bloc extends PageBloc<PageEvent, State>, State extends PageState>
    extends BlocPage<Bloc, State> {
  /// The bloc of the other page
  final Bloc bloc;

  const ReuseBlocPage({
    super.key,
    super.backGroundImage,
    super.backgroundColor,
    super.pagePadding,
    required this.bloc,
  });

  @override
  Bloc createBloc(BuildContext context) => bloc;

  @override
  Widget createBlocProvider(Widget child) {
    return BlocProvider<Bloc>.value(
      value: bloc,
      child: child,
    );
  }

  @override
  String get pageName => "pushed dynamic page";
}
