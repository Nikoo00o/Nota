import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This use case should return the current session token and also refresh it if its about to expire.
///
/// Otherwise null should be returned.
///
/// This use case will be used inside of the [RestClient]
abstract class SharedFetchCurrentSessionToken extends UseCase<SessionToken?, NoParams> {
    const SharedFetchCurrentSessionToken();
}
