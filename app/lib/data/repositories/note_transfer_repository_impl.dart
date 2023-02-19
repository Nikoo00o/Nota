import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/remote_note_data_source.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';

class NoteTransferRepositoryImpl extends NoteTransferRepository {
  final RemoteNoteDataSource remoteNoteDataSource;
  final LocalDataSource localDataSource;

  const NoteTransferRepositoryImpl({required this.remoteNoteDataSource, required this.localDataSource});

  // todo: maybe cache the start response here

}
