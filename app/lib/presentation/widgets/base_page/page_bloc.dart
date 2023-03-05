import 'package:app/presentation/widgets/base_page/page_event.dart';
import 'package:app/presentation/widgets/base_page/page_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// An abstract super class that can be used for the blocs of pages / widgets to handle the business logic and interact
/// with use cases (or in some cases repositories instead).
///
/// The template types are first [Event], then [State].
abstract class PageBloc<Event extends PageEvent, State extends PageState> extends Bloc<Event, State> {
  /// Initial state reference
  final State initialState;

  /// You can override this in the subclass bloc to decide if every event handler should display a loading dialog during
  /// its work. for this to work, of course the bloc would need a dialogService in its constructor in addition to the
  /// initial state
  bool get enableLoadingDialog => true;

  PageBloc({
    required this.initialState,
  }) : super(initialState) {
    registerEventHandlers();
  }

  /// * The method to register the Event Handlers which needs to be overwritten.
  ///
  /// This method will be called from the constructor of [PageBloc].
  ///
  /// * Inside of this method use "on&lt;Event>(callback);" to register one callback method for each event.
  /// The template type argument is optional here.
  ///
  /// The callbacks must have the following syntax: "FutureOrVoid onEvent(Event event, Emitter&lt;State> emit){...}"
  /// and inside of the callback you can return the current state with "emit(State);" multiple times.
  ///
  /// * For example for an login page bloc:
  ///
  /// ```dart
  /// class LoginPageBloc extends PageBloc &lt;LoginPageEvent, LoginPageState> {
  ///   @override
  ///   void registerEventHandlers() {
  ///     on&lt;LoginPageEventLogin>(_handleLogin);
  ///     on(_handleInitialise);// Works the same as the line above
  ///     //...
  ///   }
  ///   Future&lt;void> _handleInitialise(LoginPageEventInitialise event, Emitter&lt;LoginPageState> emit) async {
  ///     // Async callback ...
  ///     emit(LoginPageState(...));// Return specific state
  ///   }
  ///   void _handleLogin(LoginPageEventUpdate event, Emitter&lt;LoginPageState> emit) {
  ///     // Sync callback ...
  ///     emit(LoginPageState(...));// Return specific state
  ///   }
  /// //...
  /// }
  /// ```
  ///
  /// * Uncaught errors thrown in the event handlers will be handled in the onError method, so there is no need
  /// to handle the error in every [PageBloc].
  ///
  /// If an Event inherits from another Event and both have a handler registered, then the handler for the super class will
  /// also be called for the subclass Event in addition to the handler of the sub class.
  ///
  /// So for example if you have a Bloc and events which inherit from another Bloc and events and you call
  /// "super.registerEventHandlers()" in your child Bloc, then the callback methods for the parent events will also be
  /// called in the parent bloc in addition to the new callback methods in the child Bloc for the child events.
  void registerEventHandlers();

  @override
  void on<E extends Event>(EventHandler<E, State> handler, {EventTransformer<E>? transformer}) {
    super.on((E event, Emitter<State> emit) async {
      try {
        if (enableLoadingDialog) {
          // show loading dialog
        }
        await handler(event, emit);
      } finally {
        if (enableLoadingDialog) {
          // hide loading dialog
        }
      }
    }, transformer: transformer);
  }
}
