import 'package:equatable/equatable.dart';

/// Used for easy comparison for immutable objects that only have final member variables which should be included in the
/// comparison. They will be passed to the constructor as a map with descriptions and will be used in the [props] getter.
///
/// Important: If the sub class has non-final members that can change and should be used for comparison, then you have to
/// override the [props] getter and always return a new list of member variables which will be used, because otherwise the
/// changed data will not be used for comparison!
///
/// This overrides the operator== to not compare references, but the properties list instead!
abstract class ImmutableEquatable extends Equatable {
  final Map<String, Object?> _properties;

  /// The keys of the [properties] map are descriptions for the values which should contain all final member variables of
  /// the sub class that should be used for comparison!
  const ImmutableEquatable(Map<String, Object?> properties) : _properties = properties;

  @override
  List<Object?> get props => _properties.values.toList();

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln("$runtimeType {");
    _properties.forEach((String key, Object? value) {
      buffer.writeln("  $key : $value, ");
    });
    buffer.writeln("}");
    return buffer.toString();
  }
}
