import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class MenuEvent extends PageEvent {
  const MenuEvent();
}

class MenuEventInitialise extends MenuEvent {
  const MenuEventInitialise();
}
