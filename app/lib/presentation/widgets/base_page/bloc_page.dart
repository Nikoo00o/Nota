import 'package:app/core/get_it.dart';
import 'package:app/presentation/widgets/base_page/page_bloc.dart';
import 'package:app/presentation/widgets/base_page/page_event.dart';
import 'package:app/presentation/widgets/base_page/page_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// An abstract super class that can be used for the pages which are used with a bloc. You can also add another abstract
/// super class for pages without a bloc and a shared abstract super class which both extend from!
///
/// The [build] method is overridden to return both [buildPartWithNoState] and [buildPartWithState] added together. Those
/// methods can be overridden to build the page. You can also override [buildBlocProvider] if the created bloc needs any
/// parameter, or needs to add an init event. For even better performance, you could look to override [buildBlocBuilder]
/// itself!
///
/// The Template types are first [Bloc], then [State].
abstract class BlocPage<Bloc extends PageBloc<PageEvent, State>, State extends PageState> extends StatelessWidget {
  const BlocPage({super.key});

  /// Builds the bloc provider and creates the bloc. By default it will just return the singleton of the type of the Bloc
  /// from [sl], but this can be overridden to also include parameters, etc.
  ///
  /// The bloc type for the singleton must be registered as a factory and create a new object each time!
  Widget buildBlocProvider(Widget child) {
    return BlocProvider<Bloc>(
      create: (BuildContext innerContext) {
        return sl<Bloc>();
      },
      child: child,
    );
  }

  /// This builds the [BlocBuilder] around the [builder], or the [buildPartWithState] method below the [buildBlocProvider]
  /// for the access to the state changes.
  ///
  /// For better performance, you could also directly override this instead of overriding and using the
  /// [buildPartWithState] method! You could then build many different [BlocSelector] builders to access the different
  /// parts of the state that the specific widgets need for rebuilding instead of providing one big [BlocBuilder] for all
  /// widgets with all state changes.
  /// This would lead to less rebuilds of the widgets in general, because the widgets only rebuild if the specific data of
  /// the state that they need change!
  ///
  /// This is only useful if there are not many different states and the state has many different data members which can
  /// change independently from another.
  ///
  /// You can also use this method directly inside of [buildPartWithNoState] to build other parts of the app with the state.
  Widget buildBlocBuilder({Widget Function(BuildContext context, State state)? builder}) {
    return BlocBuilder<Bloc, State>(builder: builder ?? buildPartWithState);
  }

  /// Builds the part of the page that does not need to listen to state changes (with a better performance).
  ///
  /// This can be overridden, but must return the [partWithState] parameter in the final widget tree which will be build
  /// with [buildPartWithState].
  ///
  /// Per default it just returns the [partWithState].
  Widget buildPartWithNoState(BuildContext context, Widget partWithState) => partWithState;

  /// This builds the part of the page that needs to listen to state changes inside of a bloc builder. It will be inserted
  /// into the [buildPartWithNoState].
  ///
  /// Per default this just returns an empty sized box.
  Widget buildPartWithState(BuildContext context, State state) => const SizedBox();

  @override
  Widget build(BuildContext context) {
    return buildBlocProvider(buildPartWithNoState(context, buildBlocBuilder()));
  }

  /// Returns current bloc of page without listening to it, so that events can be added, or navigation can be done, etc.
  Bloc currentBloc(BuildContext context) => BlocProvider.of<Bloc>(context);

  /// Listens to the bloc for state changes and returns the bloc so that ui can be build with data from it.
  ///
  /// Important: this should only be used to create widgets, etc that depend on the bloc, but its better to just directly
  /// use the [buildBlocProvider] method instead!
  Bloc listenToBloc(BuildContext context) => context.watch<Bloc>();
}
