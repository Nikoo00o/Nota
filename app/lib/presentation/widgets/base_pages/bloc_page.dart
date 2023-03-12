import 'package:app/core/get_it.dart';
import 'package:app/presentation/widgets/base_pages/no_bloc_page.dart';
import 'package:app/presentation/widgets/base_pages/page_base.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This is an abstract super class that can be used for the pages with routes which are used with a bloc.
/// For pages without a bloc, use [NoBlocPage].
///
/// You should override the methods [buildBodyWithNoState] and [buildBodyWithState] inside of your sub class to build the
/// pages body.
///
/// You can also override [createBloc] if the created bloc needs any parameter, or if you need to send an init event to
/// the bloc.
///
/// Also look at [buildAppBar] and [buildMenuDrawer] to provide a custom [AppBar] and a custom menu drawer for this page!
///
/// Internally the [build] method returns a [createBlocProvider] with the [buildPage] as a child with then has the
/// [createBlocBuilder] as a child.
/// The [buildPage] also calls the [buildAppBar] and [buildMenuDrawer].
///
/// For even better performance, look at [createBlocSelector]!
///
/// The Template types are first [Bloc], then [State].
///
/// You can also override [customBackNavigation] to provide a custom back navigation.
abstract class BlocPage<Bloc extends PageBloc<PageEvent, State>, State extends PageState> extends PageBase {
  /// Used for building the app bar
  static const double defaultAppBarHeight = 56.0;

  const BlocPage({
    super.key,
    super.backGroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  /// Creates the bloc. By default it will just return the singleton of the type of the Bloc
  /// from [sl], but this can be overridden to also include parameters, or add an init event to the bloc, etc.
  ///
  /// The bloc type for the singleton must be registered as a factory and create a new object each time!
  Bloc createBloc(BuildContext context) => sl<Bloc>();

  /// Builds the body of the page that does not need to listen to state changes (with a better performance).
  ///
  /// This can be overridden, but must return the [bodyWithState] parameter in the final widget tree which will always be
  /// the [createBlocBuilder] which then builds the [buildBodyWithState].
  ///
  /// Of course you can also directly use multiple bloc builders with [createBlocBuilder] directly inside of the
  /// overridden method instead of overriding [buildBodyWithState] if you have multiple parts of the page where children
  /// need the state, but you have parts between them where the children do not need the state! In that case you can
  /// ignore [bodyWithState], otherwise you should return it at the correct place!
  ///
  /// Per default it just returns the [bodyWithState].
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) => bodyWithState;

  /// This builds the part of the page that needs to listen to state changes inside of the [createBlocBuilder].
  ///
  /// It will be inserted into the [buildBodyWithNoState].
  ///
  /// Per default this returns an empty [SizedBox].
  Widget buildBodyWithState(BuildContext context, State state) => const SizedBox();

  /// You can override this to build an [AppBar] that does not need access to the state for better performance.
  ///
  /// If you need access to the [State] inside of the [AppBar], then you can override this to return
  /// [createAppBarWithState] and build your app bar inside of the helper method [buildAppBarWithState]!
  ///
  /// By default this returns [null].
  PreferredSizeWidget? buildAppBar(BuildContext context) => null;

  PreferredSizeWidget createAppBarWithState(BuildContext context) {
    return PreferredSize(
      // default size
      preferredSize: const Size.fromHeight(defaultAppBarHeight),
      child: createBlocBuilder(builder: buildAppBarWithState),
    );
  }

  /// This can be overridden to build the [AppBar] with access to the [State] changes.
  ///
  /// [buildAppBar] must be overridden to return this!
  PreferredSizeWidget buildAppBarWithState(BuildContext context, State state) =>
      const PreferredSize(preferredSize: Size.zero, child: SizedBox());

  /// You can override this to build a menu drawer that does not need access to the state for better performance.
  ///
  /// If you need access to the [State] inside of the menu, then you can override this to return
  /// [createMenuDrawerWithState] and build your menu drawer inside of the helper method [buildMenuDrawerWithState]!
  ///
  /// By default this returns [null].
  Widget? buildMenuDrawer(BuildContext context) => null;

  Widget createMenuDrawerWithState(BuildContext context) {
    return createBlocBuilder(builder: buildMenuDrawerWithState);
  }

  /// This can be overridden to build the menu drawer with access to the [State] changes.
  ///
  /// [buildMenuDrawer] must be overridden to return this!
  Widget buildMenuDrawerWithState(BuildContext context, State state) => const SizedBox();

  /// For better performance, you could also directly use this inside of [buildBodyWithNoState] instead of overriding and
  /// using the [buildBodyWithState] method!
  ///
  /// You could then build many different [createBlocSelector] builders to access the different parts of the state that
  /// the specific widgets need for rebuilding instead of providing one big [createBlocBuilder] for all widgets with all
  /// state changes inside of the [buildBodyWithState].
  ///
  /// This would lead to less rebuilds of the widgets in general, because the widgets only rebuild if the specific data of
  /// the state that they need change!
  ///
  /// This is only useful if there are not many different states and the state has many different data members which can
  /// change independently from another.
  ///
  /// The [selector] callback must select the data from the [State] and return it.
  /// This selected member will then be used inside of the [builder] to build the widget.
  Widget createBlocSelector<Type>({
    required Type Function(State state) selector,
    required Widget Function(BuildContext context, Type selectedData) builder,
  }) {
    return BlocSelector<Bloc, State, Type>(selector: selector, builder: builder);
  }

  /// This builds the [BlocBuilder] around the [builder] method below the [createBlocProvider] for the access to the state
  /// changes.
  Widget createBlocBuilder({required Widget Function(BuildContext context, State state) builder}) {
    return BlocBuilder<Bloc, State>(builder: builder);
  }

  /// Builds the bloc provider and calls [createBloc].
  Widget createBlocProvider(Widget child) {
    return BlocProvider<Bloc>(
      create: (BuildContext innerContext) {
        return createBloc(innerContext);
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return createBlocProvider(
      Builder(builder: (BuildContext context) {
        // important: this wrapped builder is needed, so that the buildPartWithNoState can still access the bloc to send
        // events with the inner build context!
        return buildPage(
          context,
          buildBodyWithNoState(context, createBlocBuilder(
            builder: (BuildContext context, State state) {
              return buildBodyWithState(context, state);
            },
          )),
          buildAppBar(context),
          buildMenuDrawer(context),
        );
      }),
    );
  }

  /// Returns current bloc of page without listening to it, so that events can be added, or navigation can be done, etc.
  /// This should not be used for widgets that depend on state changes of the bloc!
  ///
  /// This can also be used to access [TextEditingController], or any other controllers inside of the widgets which are
  /// initialized once in the constructor of the bloc and are final.
  Bloc currentBloc(BuildContext context) => BlocProvider.of<Bloc>(context);

  /// Listens to the bloc for state changes and returns the bloc so that ui can be build with data from it.
  ///
  /// Important: this should only be used to create widgets, etc that depend on the bloc, but its better to just directly
  /// build widgets below the [buildBlocProvider] method instead!
  Bloc listenToBloc(BuildContext context) => context.watch<Bloc>();
}
