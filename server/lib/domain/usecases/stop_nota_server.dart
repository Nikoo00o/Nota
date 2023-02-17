import 'package:server/data/repositories/server_repository.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// Stops the nota server
class StopNotaServer extends UseCase<void, NoParams> {
  final ServerRepository serverRepository;

  const StopNotaServer({required this.serverRepository});

  @override
  Future<void> execute(NoParams params) async {
    return serverRepository.stop();
  }
}
