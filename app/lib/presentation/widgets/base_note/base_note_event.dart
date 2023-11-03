import 'dart:async';

import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';

/// shared super class for all events of the note related pages
base class BaseNoteEvent extends PageEvent {
  const BaseNoteEvent();
}

final class BaseNoteInitialized extends BaseNoteEvent {
  const BaseNoteInitialized();
}

final class BaseNoteDropDownMenuSelected extends BaseNoteEvent {
  /// zero based index of the list of menu popup buttons
  final int index;

  const BaseNoteDropDownMenuSelected({required this.index});
}

/// This is send to just rebuild the page and maybe execute some custom logic
final class BaseNoteUpdatedState extends BaseNoteEvent {
  const BaseNoteUpdatedState();
}

final class BaseNoteStructureChanged extends BaseNoteEvent {
  final StructureItem newCurrentItem;

  const BaseNoteStructureChanged({required this.newCurrentItem});
}

final class BaseNoteFavouriteChanged extends BaseNoteEvent {
  final bool isFavourite;

  const BaseNoteFavouriteChanged({required this.isFavourite});
}

final class BaseNoteBackPressed extends BaseNoteEvent {
  /// The completer returns true if no custom back navigation was executed and the default back navigation (for
  /// example navigator pop) should be executed. otherwise the completer should return false (for example if the
  /// current item is a deeper folder of the note selection that will be changed to a higher folder on navigating back)
  final Completer<bool>? shouldPopNavigationStack;

  const BaseNoteBackPressed({required this.shouldPopNavigationStack});
}
