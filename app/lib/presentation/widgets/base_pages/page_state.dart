import 'package:meta/meta.dart';
import 'package:shared/core/utils/immutable_equatable.dart';

/// Abstract helper class for all states that the bloc returns to the widget to build data on the screen.
///
/// Its best if this is immutable and does not take in references to own class types, lists, etc.
///
/// Better only have final members and make deep copies of the parameters inside of the constructor!
///
/// You can also add a copyWith method if you need to store copies of the state, but otherwise don't cache states which
/// should be directly emitted!
@immutable
abstract class PageState extends ImmutableEquatable {
  const PageState(super.properties);
}
