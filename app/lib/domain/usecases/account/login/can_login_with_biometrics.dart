import 'package:app/core/enums/required_login_status.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/account_repository.dart';
import 'package:app/domain/repositories/biometrics_repository.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This returns if the user can login with biometrics (biometrics is active and has a key from the first login)
class CanLoginWithBiometrics extends UseCase<bool, NoParams> {
  final BiometricsRepository biometricsRepository;

  const CanLoginWithBiometrics({required this.biometricsRepository});

  @override
  Future<bool> execute(NoParams params) async {
    final bool active = await biometricsRepository.isBiometricsActive();
    final bool hasKey = biometricsRepository.hasKey;
    Logger.debug("can log in with biometrics, active: $active, has key: $hasKey");
    if (active && hasKey) {
      return true;
    }
    return false;
  }
}
