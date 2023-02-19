import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/data/datasources/remote_note_data_source.dart';
import 'package:app/domain/repositories/note_repository.dart';

class NoteRepositoryImpl extends NoteRepository {
  final RemoteNoteDataSource remoteNoteDataSource;
  final LocalDataSource localDataSource;

  const NoteRepositoryImpl({required this.remoteNoteDataSource, required this.localDataSource});

  // todo: maybe cache the start response here

}
