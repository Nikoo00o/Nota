import 'package:shared/domain/usecases/usecase.dart';

/// This use case creates a new account on the server side
abstract class CreateAccount extends UseCase<void, NoParams> {
    const CreateAccount();
}
