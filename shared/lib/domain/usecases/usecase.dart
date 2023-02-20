import 'package:shared/core/utils/logger/logger.dart';

/// Helper class to use for use cases that don't have any parameters
class NoParams {
  NoParams();
}

/// Base class for all use cases with the generic [ReturnType] and [CallParams] parameters.
///
/// Call your use case like a function with the [CallParams] to execute the logic in the [execute] method which then
/// returns the [ReturnType]
abstract class UseCase<ReturnType, CallParams> {
  const UseCase();

  /// Contains the logic of the use case and has to be overridden in the use cases!
  /// This will be called by the [call] method when calling this use case like a function.
  ///
  /// Call [call] instead of this!
  Future<ReturnType> execute(CallParams params);

  /// This method makes use cases available to be called like functions with `useCase(params);`.
  Future<ReturnType> call(CallParams params) async {
    try {
      Logger.debug("Executing Use case $runtimeType...");
      return await execute(params);
    } finally {
      Logger.debug("Finished Use case $runtimeType");
    }
  }
}
