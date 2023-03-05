import 'package:meta/meta.dart';
import 'package:shared/core/utils/immutable_equatable.dart';

/// Abstract helper class for all events that the widget sends to the bloc when an action occurs.
///
/// Its best if this is immutable and does not take in references to own class types, lists, etc.
///
/// Better only have final members and make deep copies of the parameters inside of the constructor!
@immutable
abstract class PageEvent extends ImmutableEquatable {
  const PageEvent([super.properties = const <String, Object?>{}]);
}
