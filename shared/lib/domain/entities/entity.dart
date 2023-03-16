import 'package:shared/core/utils/immutable_equatable.dart';
import 'package:shared/core/utils/list_utils.dart';

/// Base class for all entities. Entities should made immutable with only final members most of the times!
///
/// If an entity does have non-final values that can be changed and should be used in comparison, override the
/// [props], or [properties] getter (look at [ImmutableEquatable] for more details and restrictions).
///
/// Otherwise use the [properties] map of the constructor and pass all final member variables that will be used for
/// comparison with description keys.
///
/// Best practice is to always make sub classes of this class immutable with only final members and then provide a
/// copyWith function that returns a new object with modified members!
abstract class Entity extends ImmutableEquatable {
  const Entity(Map<String, Object?> properties) : super(properties);

  /// This can be returned inside of the [operator ==] if you want to compare the entities without their runtimetype.
  ///
  /// This is useful so that comparing models and entities still returns tru!
  bool compareWithoutRuntimeType(Object other) =>
      identical(this, other) || other is Entity && ListUtils.equals(props, other.props);
}
