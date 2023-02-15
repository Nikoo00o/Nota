import 'dart:async';
import 'package:server/domain/entities/server_account.dart';
import 'package:server/domain/usecases/fetch_authenticated_account.dart';

/// Returns the mocked account member
class FetchAuthenticatedAccountMock extends FetchAuthenticatedAccount {
  /// Used to override the default authentication callback if its not null
  FutureOr<ServerAccount?> Function(String sessionToken)? authenticationCallbackOverride;

  FetchAuthenticatedAccountMock({required super.accountRepository});

  @override
  Future<ServerAccount?> execute(FetchAuthenticatedAccountParams params) async {
    if (authenticationCallbackOverride != null) {
      return authenticationCallbackOverride!.call(params.sessionToken);
    } else {
      return super.execute(params);
    }
  }
}
