import 'package:shared/core/utils/custom_equatable.dart';

/// Base class for all entities.
///
/// If an entity does have non-final values that can be changed and should be used in comparison, override the
/// [props] getter (look at [ImmutableEquatable] for more details).
/// Otherwise use the [properties] map of the constructor and pass all final member variables that will be used for
/// comparison with description keys.
abstract class Entity extends ImmutableEquatable {
  const Entity(Map<String, Object?> properties) : super(properties);
}
