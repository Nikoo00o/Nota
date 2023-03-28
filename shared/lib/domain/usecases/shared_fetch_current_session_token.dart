import 'package:shared/data/datasources/rest_client.dart';
import 'package:shared/domain/entities/session_token.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This use case should return the current session token and also refresh it if its about to expire.
///
/// Otherwise null should be returned.
///
/// This class is a shared base class for the real implementation and the mock that are used within of the
/// [RestClient.fetchSessionTokenCallback]
abstract class SharedFetchCurrentSessionToken extends UseCase<SessionToken?, NoParams> {
  const SharedFetchCurrentSessionToken();
}
