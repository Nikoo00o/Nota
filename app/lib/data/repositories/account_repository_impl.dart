import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/remote_account_data_source.dart';
import 'package:app/domain/repositories/account_repository.dart';

class AccountRepositoryImpl extends AccountRepository {
  final RemoteAccountDataSource remoteAccountDataSource;
  final LocalDataSource localDataSource;

  const AccountRepositoryImpl({required this.remoteAccountDataSource, required this.localDataSource});
}
