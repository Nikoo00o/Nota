import 'package:app/presentation/widgets/base_pages/page_state.dart';

class MenuState extends PageState {
  const MenuState([super.properties = const <String, Object?>{}]);
}

class MenuStateInitialized extends MenuState {
  final String? userName;

  MenuStateInitialized({required this.userName}) : super(<String, Object?>{"userName": userName});
}
