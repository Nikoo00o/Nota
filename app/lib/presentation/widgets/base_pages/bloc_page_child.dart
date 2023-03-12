import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:app/presentation/widgets/base_pages/page_helper_mixin.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';
import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This is an abstract super class that can be used for the children widgets which are used to build parts of a [BlocPage]!
///
/// Its always good for the performance to refactor large build helper methods of the bloc page into separate widget
/// classes inside of a "widgets" subfolder of the page .
///
/// This class only provides easy access to the bloc by offering the methods [buildWithNoState] and [buildWithState].
///
/// These methods will be directly returned by the build method and nothing else will be added except the bloc builder
/// around the [buildWithState].
///
/// The Template types are first [Bloc], then [State].
abstract class BlocPageChild<Bloc extends PageBloc<PageEvent, State>, State extends PageState> extends WidgetBase
    with PageHelperMixin {
  const BlocPageChild({super.key});

  /// Builds the part of the child that does not need to listen to state changes (with a better performance).
  ///
  /// This can be overridden, but must return the [partWithState] parameter in the final widget tree which will always be
  /// the [createBlocBuilder] which then builds the [buildWithState].
  ///
  /// Of course you can also directly use multiple bloc builders with [createBlocBuilder] directly inside of the
  /// overridden method instead of overriding [buildWithState] if you have multiple parts of the page where children need
  /// the state, but you have parts between them where the children do not need the state! In that case you can ignore
  /// [buildWithState], otherwise you should return it at the correct place!
  ///
  /// Per default it just returns the [buildWithState].
  Widget buildWithNoState(BuildContext context, Widget partWithState) => partWithState;

  /// This builds the part of the child that needs to listen to state changes inside of the [createBlocBuilder].
  ///
  /// It will be inserted into the [buildWithNoState].
  ///
  /// Per default this returns an empty [SizedBox].
  Widget buildWithState(BuildContext context, State state) => const SizedBox();

  /// For better performance, you could also directly use this inside of [buildWithNoState] instead of overriding and
  /// using the [buildWithState] method!
  ///
  /// You could then build many different [createBlocSelector] builders to access the different parts of the state that
  /// the specific widgets need for rebuilding instead of providing one big [createBlocBuilder] for all widgets with all
  /// state changes inside of the [buildWithState].
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

  @override
  Widget build(BuildContext context) {
    return buildWithNoState(context, createBlocBuilder(
      builder: (BuildContext context, State state) {
        return buildWithState(context, state);
      },
    ));
  }

  /// Returns current bloc of hte page without listening to it, so that events can be added, or navigation can be done, etc.
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
