import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/usecases/note_transfer/transfer_notes.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// Just returns the TimeStamp of the last successful call to [TransferNotes]. This is used to display which notes have
/// changed and need to be synced to the server.
class GetLastNoteTransferTime extends UseCase<DateTime, NoParams> {
  final LocalDataSource localDataSource;

  const GetLastNoteTransferTime({required this.localDataSource});

  @override
  Future<DateTime> execute(NoParams params) async {
    return localDataSource.getLastNoteTransferTime();
  }
}
